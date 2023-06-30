#!/bin/env python3
# Generate test cases for words count labs.

# To generate one additional test case means to add

import random
import os
from collections import defaultdict
from functools import reduce


def generate_string_n_words(n: int) -> (list, defaultdict):
    # Make some vocabulary, everything UTF-8
    latin = ["He", "Jiří", "pre-order"]
    cyrylics = ["Київ", "з-під"]
    hindi = ["तत्वमीमांसा", "तत्वज्ञान", "सौंदर्यशास्त्र"]
    chinees = ["做", "吃", "知道"]
    same_words_diff_case_cyrylics = ["мАлЕньКі", "маленькі"]
    same_words_diff_case_latin = ["Vim", "vIm", "VIM"]

    # The Word in this task - sequence of characters separated with C++ isspace() function.
    # isspace() returns true for:
    spaces = ['\n', '\t', '\v', '\f', ' ']
    # Punctuation at the beginning and at the very end should be ignored
    punctuation = [",", ".", "?", "!", " - ", "/", "]", "[", "(", ")", "^", "#", "\'", "\""]

    # As far as it is not important in this task to have words separated by some type, just put them all in one list
    vocabulary = latin + cyrylics + chinees + hindi + same_words_diff_case_cyrylics + same_words_diff_case_latin

    res = []
    res_count = defaultdict(lambda: 0, {})
    for i in range(n):
        current_word: str
        prob_space2 = random.random() > 0.5
        prob_punct = random.random() > 0.5
        current_word = random.choice(vocabulary)
        res_count[current_word.lower()] += 1
        current_word += random.choice(punctuation) * prob_punct + random.choice(spaces) + random.choice(
            spaces) * prob_space2
        res.append(current_word)
    # print(res)
    return "".join(res), res_count


def generate_tests(zipname: str, num_files: int, num_words_each_file: list[int, int]):
    assert num_files != len(num_words_each_file), "wrong parameter; len(num_words_each_file) should be eq to num_files"
    os.mkdir("tmp")
    os.chdir("tmp")
    test_name = "test_" + str(reduce(lambda x, y: x * y, num_words_each_file) * num_files)
    os.mkdir(test_name)
    os.chdir(test_name)
    # to detect issues with recursive walk
    dir_depth = 3
    for i in range(1, dir_depth + 1):
        os.mkdir(str(i))
        os.chdir(str(i))

    final_dict = {}
    for i in range(num_files):
        file_text, file_count = generate_string_n_words(num_words_each_file[i])
        with open("i.txt", 'w') as f:
            f.write(file_text)
        final_dict.update(file_count)
    os.chdir("../" * dir_depth)
    # save_final_dict()


if __name__ == "__main__":
    res, res_cnt = generate_string_n_words(3)
    res2, res_cnt2 = generate_string_n_words(4)
    print("".join([res, res2]))
    res_cnt.update(res_cnt2)
    print(res_cnt)
