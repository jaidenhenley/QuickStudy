#!/usr/bin/env python3
"""Usage: shift-dates.py <reference Sessions.json> <src> <dst> [<src> <dst> ...]

Copies each src to dst with every ISO-8601 timestamp moved by a whole number of days, chosen so
the newest session in the reference file starts today (local time). Keeps recorded study history
inside the streak and retention windows however old the fixture is.
"""
import json
import re
import sys
from datetime import datetime, timedelta, timezone

STAMP = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z")


def parse(text):
    return datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def main():
    reference, pairs = sys.argv[1], sys.argv[2:]
    if len(pairs) % 2:
        sys.exit("src/dst arguments must come in pairs")
    with open(reference) as handle:
        newest = max(parse(session["startedAt"]) for session in json.load(handle))
    delta = datetime.now().astimezone().date() - newest.astimezone().date()

    def shift(match):
        return (parse(match.group(0)) + timedelta(days=delta.days)).strftime("%Y-%m-%dT%H:%M:%SZ")

    for source, destination in zip(pairs[::2], pairs[1::2]):
        with open(source) as handle:
            text = handle.read()
        with open(destination, "w") as handle:
            handle.write(STAMP.sub(shift, text))


main()
