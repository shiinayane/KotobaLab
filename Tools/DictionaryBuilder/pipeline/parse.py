#
#  parse.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/04.
#

from typing import Any
from models.dictionary_entry import ParsedDictionaryEntry


def parse_semantic(entry: list[Any]) -> dict:
    content = entry[5]

    result = {
        "pos": None,
        "glosses": [],
        "forms": [],
    }

    def walk(node: Any, in_glossary=False):
        if isinstance(node, dict):
            tag = node.get("tag")
            data = node.get("data", {})
            content = node.get("content")

            # --------------------------
            # 1. 提取词性（part-of-speech）
            # --------------------------
            if tag == "span" and data.get("content") == "part-of-speech-info":
                if isinstance(content, str):
                    result["pos"] = content.strip()

            # --------------------------
            # 2. 提取 definitions（glossary）
            # --------------------------
            if tag == "ul" and data.get("content") == "glossary":
                in_glossary = True

            if tag == "li" and in_glossary:
                if isinstance(content, str):
                    result["glosses"].append(content.strip())

            # --------------------------
            # 3. 提取 forms（变体）
            # --------------------------
            if tag == "div" and data.get("content") == "forms":
                extract_forms(content)

            # 继续递归
            if isinstance(content, list):
                for child in content:
                    walk(child, in_glossary)
            elif isinstance(content, dict):
                walk(content, in_glossary)

        elif isinstance(node, list):
            for item in node:
                walk(item, in_glossary)

    def extract_forms(node: Any):
        """专门提取 forms 列表"""
        if isinstance(node, dict):
            tag = node.get("tag")
            content = node.get("content")

            if tag == "li":
                if isinstance(content, str):
                    result["forms"].append(content.strip())

            if isinstance(content, list):
                for child in content:
                    extract_forms(child)
            elif isinstance(content, dict):
                extract_forms(content)

        elif isinstance(node, list):
            for item in node:
                extract_forms(item)

    # 开始解析
    walk(content, False)

    # 去重（很重要）
    result["glosses"] = list(dict.fromkeys(result["glosses"]))
    result["forms"] = list(dict.fromkeys(result["forms"]))

    return result


def parse_entry(entry: list[Any]) -> ParsedDictionaryEntry:
    semantic = parse_semantic(entry)

    return ParsedDictionaryEntry(
        term=entry[0],
        reading=entry[1] or None,
        sequence=entry[6],
        part_of_speech=semantic["pos"],
        glosses=semantic["glosses"],
        forms=semantic["forms"]
    )
