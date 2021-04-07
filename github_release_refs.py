# -*- coding: utf-8 -*-

import urllib3
import json
import os
import re
import sys

# TODO: only_version doesn't account for semver rc/pre/alpha
only_version = re.compile(r'([0-9]+(\.[0-9]+)+)')

http = urllib3.PoolManager(timeout=urllib3.Timeout(connect=7.0, read=3.0))

headers = {
    "accept": "application/json",
    "user-agent": "bazel/TODO:<bazel version from env>",
}

if __name__ == '__main__':
    url = sys.argv[1]
    auth_token = sys.argv[2]
    release = sys.argv[3]
    if len(sys.argv) != 4:
        print("Usage: <url> <token> <name>", file=sys.stderr)
        exit(1)

    if auth_token:
        headers['authorization'] = 'token ' + auth_token

    r = http.request('GET', url, headers=headers)
    if r.status != 200:
        print("{} status: {}".format(url, r.status), file=sys.stderr)
        exit(1)

    releases = json.loads(r.data.decode('utf-8'))
    for rel in releases:
        if rel['draft']:
            continue
        # if rel['prerelease']:
        #     continue

        tag = rel['tag_name']
        tag_digits = only_version.findall(tag)
        if not tag_digits:
            print("no digits in {}".format(tag), file=sys.stderr)
            exit(1)
        tag_digits = tag_digits[0][0]

        expected = release.format(tag=tag, tag_digits=tag_digits)
        for asset in rel['assets']:
            url = asset['browser_download_url']

            name = os.path.basename(url)
            if name != expected:
                continue

            ty = {
                'application/x-compressed': 'tar.gz',
                'application/x-compressed-tar': 'tar.gz',
                'application/x-zip-compressed': 'zip',
                'application/zip': 'zip',
            }[asset['content_type']]

            print("{tag}\t{tag_digits}\t{ty}\t{url}".format(
                tag=tag,
                tag_digits=tag_digits,
                ty=ty,
                url=url,
            ))
