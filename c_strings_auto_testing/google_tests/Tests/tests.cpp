// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: http://www.viva64.com


/*
 * c++ strings tests
 *
 * Tests are written based on lab work of Death Grips Fan Club:
 * Teodor Muzychuk
 * Ostap Seryvko
 * Roman Mutel
 * Taras Yaroshko
 *
 * And also based on myralllka c strings tests
 *
 * Some tests are also taken from the following team:
 * Sofiia Folvarochna
 * Serhii Ivanov
 * Anastasiia Beheni
 * Olesia Omelchuk
 *
 * ᓚᘏᗢ cat :)
 */


#include <gtest/gtest.h>
#include <iostream>
#include <string>
#include <exception>
#include <limits>

#include "mystring.hpp"


//!!!!!!!!!!uncomment if you want to test additional task!!!!!!!!!!
// #define EXTRA_PLUS_MULT

using namespace std::string_literals;

namespace {
    class ClassDeclaration : public testing::Test {
    protected:
        ClassDeclaration() = default;

        my_str_t string_size_20 = my_str_t{20, 'c'};
        my_str_t string_size_2 = my_str_t{2, 'c'};
        my_str_t string_empty = my_str_t("");

        // test copy constructor
        my_str_t string_size_2_copy = my_str_t(string_size_2);
    };

}

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!MAIN TESTS!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/*
 *  test constructors and state after creation
 *  !IMPORTANT! No unified method to increase capacity
 *  !IMPORTANT! Checks if capacity is ge than size
 *  !IMPORTANT! Should be checked manually
 */
TEST_F(ClassDeclaration, constructors) {
    // test string parameters after create
    EXPECT_EQ(string_size_20.size(), 20);
    EXPECT_GE(string_size_20.capacity(), string_size_20.size());

    EXPECT_EQ(string_size_2.size(), 2);
    EXPECT_GE(string_size_2.capacity(), string_size_2.size());

    EXPECT_EQ(string_empty.size(), 0);
    EXPECT_GE(string_empty.capacity(), string_empty.size());

    string_size_2_copy[0] = 'm';
    EXPECT_NE(string_size_2, string_size_2_copy);

    // test create return code if string != NULL
    ASSERT_NO_THROW(my_str_t(20, 'c'));
    ASSERT_NO_THROW(my_str_t("c_string"));
    ASSERT_NO_THROW(my_str_t("c++_string"s));

    // should assert 1 out of 2. TODO: rewrite to have one assert
    ASSERT_ANY_THROW((my_str_t{std::numeric_limits<size_t>::max()/100, 'c'}));
}

/*
 * index operators
 */
TEST_F(ClassDeclaration, index_operators) {
    my_str_t test_index = my_str_t("hi, hello, hola!");

    ASSERT_EQ(test_index[1], 'i');
    ASSERT_EQ(test_index.at(2), ',');

    EXPECT_ANY_THROW(test_index.at(100));

    test_index[3] = 'h';

    ASSERT_EQ(test_index, my_str_t("hi,hhello, hola!"));
}

/*
 *  test of assignment operator
 */
TEST_F(ClassDeclaration, assign_operator) {
    my_str_t assign_to = my_str_t("hello world!");
    my_str_t assign_this = my_str_t("goodbye world! see you soon!");

    EXPECT_EQ(assign_to.size(), 12);
    EXPECT_GE(assign_to.capacity(), assign_to.size());

    EXPECT_EQ(assign_this.size(), 28);
    EXPECT_GE(assign_this.capacity(), assign_this.size());

    assign_to = assign_this;

    EXPECT_EQ(assign_this.size(), 28);
    EXPECT_GE(assign_this.capacity(), assign_this.size());

    EXPECT_EQ(assign_to.size(), 28);
    EXPECT_GE(assign_to.capacity(), assign_to.size());

    EXPECT_EQ(assign_to, assign_this);

    assign_to[0] = 'G';

    EXPECT_NE(assign_to, assign_this);
}

/*
 * test swap
 */
TEST_F(ClassDeclaration, swap) {
    my_str_t swap_1 = my_str_t("bongiorno, ragazzi!");
    my_str_t swap_2 = my_str_t("arrivederci, amici!!!");

    EXPECT_EQ(swap_1.size(), 19);
    EXPECT_GE(swap_1.capacity(), swap_1.size());

    EXPECT_EQ(swap_2.size(), 21);
    EXPECT_GE(swap_2.capacity(), swap_2.size());

    swap_1.swap(swap_2);

    EXPECT_EQ(swap_2.size(), 19);
    EXPECT_GE(swap_2.capacity(), swap_2.size());

    EXPECT_EQ(swap_1.size(), 21);
    EXPECT_GE(swap_1.capacity(), swap_1.size());

    EXPECT_EQ(swap_2, my_str_t("bongiorno, ragazzi!"));
    EXPECT_EQ(swap_1, my_str_t("arrivederci, amici!!!"));
}


/*
 * reserve, shrink_to_fit
 * reserve - should it change capacity exactly to the given value or can it round the value?
 */
TEST_F(ClassDeclaration, reserve_shrink) {
    // reserve
    my_str_t test_cap = my_str_t("hi, hi, hi, hi, hi!!!");
    EXPECT_EQ(test_cap.size(), 21);
    auto prev_cap = test_cap.capacity();
    EXPECT_GE(test_cap.capacity(), test_cap.size());

    test_cap.reserve(15);
    EXPECT_EQ(test_cap.capacity(), prev_cap);

    test_cap.reserve(53);
    EXPECT_EQ(test_cap.capacity(), 53);

    // shrink_to_fit
    test_cap.shrink_to_fit();
    EXPECT_LT(test_cap.capacity(), 53);
}

/*
 *  resize, clear
 */
TEST_F(ClassDeclaration, res_clear) {
    // resize
    my_str_t test_res = my_str_t("hi, buongiorno, buonasera, arrivederci!!!!");

    EXPECT_EQ(test_res.size(), 42);
    EXPECT_GE(test_res.capacity(), test_res.size());

    auto prev_cap = test_res.capacity();

    test_res.resize(25);
    EXPECT_EQ(test_res.size(), 25);
    EXPECT_EQ(test_res, my_str_t("hi, buongiorno, buonasera"));

    test_res.resize(30);
    EXPECT_EQ(test_res.size(), 30);
    EXPECT_EQ(test_res.capacity(), prev_cap);
    EXPECT_EQ(test_res, my_str_t("hi, buongiorno, buonasera     "));

    // check this!!!!
    test_res.resize(prev_cap + 5, 'a');
    EXPECT_EQ(test_res.size(), prev_cap + 5);
    EXPECT_GE(test_res.capacity(), test_res.size());

    // clear
    test_res.clear();
    EXPECT_EQ(test_res.size(), 0);
}

/*
 * insert char
 */

TEST_F(ClassDeclaration, insert_char) {
    // insert
    my_str_t test_insert = my_str_t("hi, hello, hola");
    auto my_capacity = 18;
    test_insert.reserve(my_capacity);
    EXPECT_EQ(test_insert.size(), 15);
    EXPECT_GE(test_insert.capacity(), my_capacity);

    // insert char inside
    test_insert.insert(2, 'i');
    EXPECT_EQ(test_insert, my_str_t("hii, hello, hola"));
    EXPECT_EQ(test_insert.size(), 16);
    EXPECT_GE(test_insert.capacity(), my_capacity);

    // insert char at size()
    test_insert.insert(test_insert.size(), '!');
    EXPECT_EQ(test_insert, my_str_t("hii, hello, hola!"));
    EXPECT_EQ(test_insert.size(), 17);
    EXPECT_GE(test_insert.capacity(), my_capacity);

    // insert char at 0
    test_insert.insert(0, 'h');
    EXPECT_EQ(test_insert, my_str_t("hhii, hello, hola!"));
    EXPECT_EQ(test_insert.size(), 18);
    EXPECT_GE(test_insert.capacity(), my_capacity);

    // insert char at bad position
    EXPECT_THROW(test_insert.insert(test_insert.size()+1, 'h'), std::out_of_range);
    EXPECT_EQ(test_insert, my_str_t("hhii, hello, hola!"));
    EXPECT_EQ(test_insert.size(), 18);
    EXPECT_GE(test_insert.capacity(), my_capacity);

    // insert char with extending buffer
    test_insert.insert(8, 'l');
    EXPECT_EQ(test_insert, my_str_t("hhii, helllo, hola!"));
    EXPECT_EQ(test_insert.size(), 19);
    EXPECT_GT(test_insert.capacity(), my_capacity);

    // insert char in empty string
    my_str_t empty_str = my_str_t("");
    empty_str.insert(0, 't');
    EXPECT_EQ(empty_str, my_str_t("t"));
    EXPECT_EQ(empty_str.size(), 1);
    EXPECT_GE(empty_str.capacity(), empty_str.size());
}

/*
 * insert my_str
 */
TEST_F(ClassDeclaration, insert_my_str) {
    my_str_t test_insert_my_str = my_str_t("hi, how are you?");
    auto my_capacity = test_insert_my_str.capacity() + 16;
    test_insert_my_str.reserve(my_capacity);
    EXPECT_EQ(test_insert_my_str.size(), 16);
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);

    // normal insert
    test_insert_my_str.insert(3, my_str_t(" friend,"));
    EXPECT_EQ(test_insert_my_str, my_str_t("hi, friend, how are you?"));
    EXPECT_EQ(test_insert_my_str.size(), 24);
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);

    // insert at the end of the string
    test_insert_my_str.insert(test_insert_my_str.size(), my_str_t(" I am fine!"));
    EXPECT_EQ(test_insert_my_str, my_str_t("hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_my_str.size(), 35);

    // test if capacity increased
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);

    // insert at the start of the string
    test_insert_my_str.insert(0, my_str_t("hii, "));
    EXPECT_EQ(test_insert_my_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_my_str.size(), 40);
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);

    // insert empty string
    test_insert_my_str.insert(3, my_str_t(""));
    EXPECT_EQ(test_insert_my_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_my_str.size(), 40);
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);

    // insert in the empty string
    my_str_t test_insert_empty = my_str_t("");
    EXPECT_EQ(test_insert_empty.size(), 0);
    EXPECT_GE(test_insert_empty.capacity(), test_insert_empty.size());
    test_insert_empty.insert(0, my_str_t("hi, welcome!"));
    EXPECT_EQ(test_insert_empty, my_str_t("hi, welcome!"));
    EXPECT_EQ(test_insert_empty.size(), 12);
    EXPECT_GE(test_insert_empty.capacity(), test_insert_empty.size());

    // insert at wrong position
    EXPECT_THROW(test_insert_my_str.insert(100, my_str_t("No:(")), std::out_of_range);
    EXPECT_EQ(test_insert_my_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_my_str.size(), 40);
    EXPECT_GE(test_insert_my_str.capacity(), my_capacity);
}

/*
 *  insert c string
 */
TEST_F(ClassDeclaration, insert_c_string) {
    my_str_t test_insert_c_str = my_str_t("hi, how are you?");
    auto my_capacity = test_insert_c_str.capacity() + 16;
    test_insert_c_str.reserve(my_capacity);
    EXPECT_EQ(test_insert_c_str.size(), 16);
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);

    // normal insert
    test_insert_c_str.insert(3, " friend,");
    EXPECT_EQ(test_insert_c_str, my_str_t("hi, friend, how are you?"));
    EXPECT_EQ(test_insert_c_str.size(), 24);
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);

    // insert at the end of the string
    test_insert_c_str.insert(test_insert_c_str.size(), " I am fine!");
    EXPECT_EQ(test_insert_c_str, my_str_t("hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_c_str.size(), 35);
    // test if capacity increased
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);

    // insert at the start of the string
    test_insert_c_str.insert(0, "hii, ");
    EXPECT_EQ(test_insert_c_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_c_str.size(), 40);
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);

    // insert empty string
    test_insert_c_str.insert(3, "");
    EXPECT_EQ(test_insert_c_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_c_str.size(), 40);
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);

    // insert in the empty string
    my_str_t test_insert_empty_c = my_str_t("");
    EXPECT_EQ(test_insert_empty_c.size(), 0);
    EXPECT_GE(test_insert_empty_c.capacity(), test_insert_empty_c.size());
    test_insert_empty_c.insert(0, "hi, welcome!");
    EXPECT_EQ(test_insert_empty_c, my_str_t("hi, welcome!"));
    EXPECT_EQ(test_insert_empty_c.size(), 12);
    EXPECT_GE(test_insert_empty_c.capacity(), test_insert_empty_c.size());

    // insert at wrong position
    EXPECT_THROW(test_insert_c_str.insert(100, "No:("), std::out_of_range);
    EXPECT_EQ(test_insert_c_str, my_str_t("hii, hi, friend, how are you? I am fine!"));
    EXPECT_EQ(test_insert_c_str.size(), 40);
    EXPECT_GE(test_insert_c_str.capacity(), my_capacity);
}

/*
 * append char
 */
TEST_F(ClassDeclaration, append_char) {
    my_str_t test_append_char = my_str_t("I love c++ strings lab!!!");
    auto my_capacity = test_append_char.capacity() + 16;
    test_append_char.reserve(my_capacity);
    EXPECT_EQ(test_append_char.size(), 25);
    EXPECT_GE(test_append_char.capacity(), my_capacity);

    // normal append
    test_append_char.append('q');
    EXPECT_EQ(test_append_char, my_str_t("I love c++ strings lab!!!q"));
    EXPECT_EQ(test_append_char.size(), 26);
    EXPECT_GE(test_append_char.capacity(), my_capacity);

    // test capacity increse
    test_append_char.append('q');
    test_append_char.append('q');
    test_append_char.append('q');
    test_append_char.append('q');
    test_append_char.append('q');
    test_append_char.append('q');
    EXPECT_EQ(test_append_char, my_str_t("I love c++ strings lab!!!qqqqqqq"));
    EXPECT_EQ(test_append_char.size(), 32);
    EXPECT_GE(test_append_char.capacity(), my_capacity);


    // append to empty string
    my_str_t test_empty_char = my_str_t("");
    EXPECT_EQ(test_empty_char.size(), 0);
    EXPECT_GE(test_empty_char.capacity(), test_empty_char.size());
    test_empty_char.append('w');
    EXPECT_EQ(test_empty_char, my_str_t("w"));
    EXPECT_EQ(test_empty_char.size(), 1);
    EXPECT_GE(test_empty_char.capacity(), test_empty_char.size());
}

/*
 * append my_str
 */
TEST_F(ClassDeclaration, append_my_str) {
    my_str_t test_append_my_str = my_str_t("I love c++ strings lab!!!");
    auto my_capacity = test_append_my_str.capacity() + 16;
    test_append_my_str.reserve(my_capacity);
    EXPECT_EQ(test_append_my_str.size(), 25);
    EXPECT_GE(test_append_my_str.capacity(), my_capacity);

    // normal append
    test_append_my_str.append(my_str_t(" Very much!!!"));
    EXPECT_EQ(test_append_my_str, my_str_t("I love c++ strings lab!!! Very much!!!"));
    EXPECT_EQ(test_append_my_str.size(), 38);
    // test buffer increase
    EXPECT_GE(test_append_my_str.capacity(), my_capacity);

    // append empty string
    test_append_my_str.append(my_str_t(""));
    EXPECT_EQ(test_append_my_str, my_str_t("I love c++ strings lab!!! Very much!!!"));
    EXPECT_EQ(test_append_my_str.size(), 38);
    EXPECT_GE(test_append_my_str.capacity(), my_capacity);

    // append to empty string
    my_str_t test_empty_my_str = my_str_t("");
    EXPECT_EQ(test_empty_my_str.size(), 0);
    EXPECT_GE(test_empty_my_str.capacity(), test_empty_my_str.size());
    test_empty_my_str.append(my_str_t("hiiii"));
    EXPECT_EQ(test_empty_my_str, my_str_t("hiiii"));
    EXPECT_EQ(test_empty_my_str.size(), 5);
    EXPECT_GE(test_empty_my_str.capacity(), test_empty_my_str.size());
}


/*
 * append c str
 */
TEST_F(ClassDeclaration, append_c_str) {
    my_str_t test_append_c_str = my_str_t("I love c++ strings lab!!!");
    auto my_capacity = test_append_c_str.capacity() + 16;
    test_append_c_str.reserve(my_capacity);
    EXPECT_EQ(test_append_c_str.size(), 25);
    EXPECT_GE(test_append_c_str.capacity(), my_capacity);

    // normal append
    test_append_c_str.append(" Very much!!!");
    EXPECT_EQ(test_append_c_str, my_str_t("I love c++ strings lab!!! Very much!!!"));
    EXPECT_EQ(test_append_c_str.size(), 38);
    // test buffer increase
    EXPECT_GE(test_append_c_str.capacity(), my_capacity);

    // append empty string
    test_append_c_str.append("");
    EXPECT_EQ(test_append_c_str, my_str_t("I love c++ strings lab!!! Very much!!!"));
    EXPECT_EQ(test_append_c_str.size(), 38);
    EXPECT_GE(test_append_c_str.capacity(), my_capacity);

    // append to empty string
    my_str_t test_empty_c_str = my_str_t("");
    EXPECT_EQ(test_empty_c_str.size(), 0);
    EXPECT_GE(test_empty_c_str.capacity(), test_empty_c_str.size());
    test_empty_c_str.append("hiiii");
    EXPECT_EQ(test_empty_c_str, my_str_t("hiiii"));
    EXPECT_EQ(test_empty_c_str.size(), 5);
    EXPECT_GE(test_empty_c_str.capacity(), test_empty_c_str.size());
}

/*
 * erase
 */
TEST_F(ClassDeclaration, erase_test) {
    my_str_t test_erase = my_str_t("Hi, hello, hola, ciao, buongiorno!!!");
    EXPECT_EQ(test_erase.size(), 36);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase inside
    test_erase.erase(3, 7);
    EXPECT_EQ(test_erase, my_str_t("Hi, hola, ciao, buongiorno!!!"));
    EXPECT_EQ(test_erase.size(), 29);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase from the start
    test_erase.erase(0, 4);
    EXPECT_EQ(test_erase, my_str_t("hola, ciao, buongiorno!!!"));
    EXPECT_EQ(test_erase.size(), 25);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase to the end (out of bounds)
    test_erase.erase(22, 10);
    EXPECT_EQ(test_erase, my_str_t("hola, ciao, buongiorno"));
    EXPECT_EQ(test_erase.size(), 22);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase from the end
    test_erase.erase(test_erase.size()-1, 10);
    EXPECT_EQ(test_erase, my_str_t("hola, ciao, buongiorn"));
    EXPECT_EQ(test_erase.size(), 21);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // bad range
    EXPECT_THROW(test_erase.erase(test_erase.size()+5, 10), std::out_of_range);
    EXPECT_EQ(test_erase, my_str_t("hola, ciao, buongiorn"));
    EXPECT_EQ(test_erase.size(), 21);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // size is zero
    test_erase.erase(3, 0);
    EXPECT_EQ(test_erase, my_str_t("hola, ciao, buongiorn"));
    EXPECT_EQ(test_erase.size(), 21);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase everything
    test_erase.erase(0, 30);
    EXPECT_EQ(test_erase, my_str_t(""));
    EXPECT_EQ(test_erase.size(), 0);
    EXPECT_GE(test_erase.capacity(), test_erase.size());

    // erase empty string
    test_erase.erase(0, 20);
    EXPECT_EQ(test_erase, my_str_t(""));
    EXPECT_EQ(test_erase.size(), 0);
    EXPECT_GE(test_erase.capacity(), test_erase.size());
}

/*
 * c_str test
 */
TEST_F(ClassDeclaration, c_str_test) {
    my_str_t test_c_str = my_str_t("hiiiiii");
    EXPECT_EQ(test_c_str.size(), 7);
    EXPECT_GE(test_c_str.capacity(), test_c_str.size());

    EXPECT_STREQ(test_c_str.c_str(), "hiiiiii");
}

/*
 * find char
 */
TEST_F(ClassDeclaration, find_char){
    my_str_t test("Mutel");
    size_t not_found = -1;
    EXPECT_EQ(test.size(), 5);
    EXPECT_GE(test.capacity(), test.size());


    EXPECT_EQ(test.find('u', 1), 1);
    EXPECT_EQ(test.find('M'), 0);
    EXPECT_EQ(test.find('M', 2), not_found);
    EXPECT_EQ(test.find('l', 3), 4);
    EXPECT_EQ(test.find('c'), not_found);

    // empty test
    my_str_t empty_test("");
    EXPECT_EQ(empty_test.find('w'), not_found);

    EXPECT_THROW(test.find('c', 100), std::out_of_range);
}

/*
 * find substring c and std::string
 */
TEST_F(ClassDeclaration, find_sub_c_std){
    my_str_t test("Yaroshko");
    EXPECT_EQ(test.size(), 8);
    EXPECT_GE(test.capacity(), test.size());

    size_t not_found = -1;
    EXPECT_EQ(test.find("osh"), 3);
    EXPECT_EQ(test.find(std::string("osh")), 3);

    EXPECT_EQ(test.find("Yar"), 0);
    EXPECT_EQ(test.find(std::string("Yar")), 0);

    EXPECT_EQ(test.find("Yar", 1), not_found);
    EXPECT_EQ(test.find(std::string("Yar"), 1), not_found);

    EXPECT_EQ(test.find("ko", 3), 6);
    EXPECT_EQ(test.find(std::string("ko"), 3), 6);

    EXPECT_EQ(test.find("ko", 8), not_found);
    EXPECT_EQ(test.find(std::string("ko"), 8), not_found);

    EXPECT_EQ(test.find("osho"), not_found);
    EXPECT_EQ(test.find(std::string("osho")), not_found);

    EXPECT_EQ(test.find("yvk"), not_found);
    EXPECT_EQ(test.find(std::string("yvk")), not_found);

    // empty string test
    my_str_t empty_test("");
    EXPECT_EQ(empty_test.find("yvk"), not_found);
    EXPECT_EQ(empty_test.find(""), not_found);
    EXPECT_EQ(empty_test.find(std::string("yvk")), not_found);
    EXPECT_EQ(empty_test.find(std::string("")), not_found);

    EXPECT_THROW(test.find("yvk", 100), std::out_of_range);
    EXPECT_THROW(test.find(std::string("yvk"), 100), std::out_of_range);
}

/*
 * substr test
 */
TEST_F(ClassDeclaration, substr_test){
    my_str_t test("Seryvko");
    EXPECT_EQ(test.size(), 7);
    EXPECT_GE(test.capacity(), test.size());

    EXPECT_EQ(test.substr(2, 4), "ryvk");
    EXPECT_EQ(test.substr(0, 0), "");
    EXPECT_EQ(test.substr(3, 10), "yvko");
    EXPECT_EQ(test.substr(6, 10), "o");

    // empty string test
    my_str_t empty_test("");
    EXPECT_EQ(empty_test.substr(0, 10), "");

    EXPECT_THROW(test.substr(8, 10), std::out_of_range);
}

/*
 * equality operator
 */
TEST_F(ClassDeclaration, equality_operator){
    my_str_t test("Muzychu");
    my_str_t test1("appendedmystr");
    EXPECT_EQ(test == test1, false);
    EXPECT_EQ(test == "ychuMuz", false);
    EXPECT_EQ(test == "Muzychu", true);
    EXPECT_EQ("Muzychu" == test, true);
    EXPECT_EQ(test != test1, true);
    EXPECT_EQ(test != "Muzychu", false);
    EXPECT_EQ("Muzychu" != test, false);
    // extra task - can't be in tests
   // EXPECT_EQ(test + "appendedmystr", "Muzychu" + test1);
}

/*
 * inequality operator
 */
TEST_F(ClassDeclaration, inequality_operator){
    my_str_t test("Muzychu");
    my_str_t test1("appendedmystr");
    EXPECT_EQ(test < test1, true);
    EXPECT_EQ(test < "Muzychu", false);
    EXPECT_EQ("Muzychu" < test, false);
    EXPECT_EQ(test > test1, false);
    EXPECT_EQ(test > "Muzychu", false);
    EXPECT_EQ("Muzychu" > test, false);
    EXPECT_EQ(test <= test1, true);
    EXPECT_EQ(test <= "Muzychu", true);
    EXPECT_EQ("Muzychu" <= test, true);
    EXPECT_EQ(test >= test1, false);
    EXPECT_EQ(test >= "Muzychu", true);
    EXPECT_EQ("Muzychu" >= test, true);
    EXPECT_EQ(my_str_t("abcd") > my_str_t("abcc"), true);
}

/*
 * stdin stdout streams
 */
TEST_F(ClassDeclaration, stdin_out) {
    std::stringstream ss;
    ss << "       hello";
    my_str_t str7{"1"};
    ss >> str7;

    EXPECT_EQ(str7, "hello");
}

/*
 * readline
 */
TEST_F(ClassDeclaration, readline_test) {
    std::stringstream ss1;
    ss1 <<"   hello\nworld";
    my_str_t str5{"1"};
    readline(ss1, str5);

    EXPECT_EQ(str5, "   hello");
}

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!EXTRA TASK!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#ifdef EXTRA_PLUS_MULT
/*
 * multiply operator
 */
TEST(OperatorsTest, multiply_operator){
    my_str_t test("Muzychu");
    EXPECT_EQ(test * 3, "MuzychuMuzychuMuzychu");
    test *= 2;
    EXPECT_EQ(test, "MuzychuMuzychu");
    test *= 0;
    EXPECT_EQ(test, "");
    EXPECT_THROW(test *= -1, std::invalid_argument);
}

/*
 * plus operator
 */
TEST_F(ClassDeclaration, plus_operator){
    my_str_t test("Muzychu");
    my_str_t to_append("appendedmystr");
    EXPECT_EQ(test + to_append, "Muzychuappendedmystr");
    EXPECT_EQ(test + "appendedcstr", "Muzychuappendedcstr");
    EXPECT_EQ("appendedcstr" + test, "appendedcstrMuzychu");
    EXPECT_EQ(test+'c', "Muzychuc");
}

/*
 * plus equals operator
 */
TEST_F(ClassDeclaration, plus_eq_operator){
    my_str_t test("Muzychu");
    my_str_t to_append("appendedmystr");
    test += to_append;
    EXPECT_EQ(test, "Muzychuappendedmystr");
    test += "appendedcstr";
    EXPECT_EQ(test , "Muzychuappendedmystrappendedcstr");
    test+='c';
    EXPECT_EQ(test, "Muzychuappendedmystrappendedcstrc");
}

#endif

//! not in task?

//TEST(NullPtrTest, NullPtrToConstructor){
//    EXPECT_THROW(my_str_t(nullptr), std::logic_error);
//}
//
//TEST(NullPtrTest, NullPtrInsert) {
//    my_str_t null_test("test");
//    EXPECT_THROW(null_test.insert(0, nullptr), std::logic_error);
//}