#!/bin/bash -x
# Non-verbose
##!/bin/bash 

# Used to run mycat for test -- valgrind, signaling runner and so on.
# Sanitizers may require root (sudo) privileges.
RUNNER= 
EXIT_ON_FIRST_ERROR=
TEST_ON_LARGE_FILES=

# valgrind prints to stderr, so see ERRORS_FILE 
# (mycat_errors.txt by default)

while getopts "v:le" opt; do
    case "${opt}" in
        v)  RUNNER=${OPTARG};;
		e)  EXIT_ON_FIRST_ERROR="true";;
		l)  TEST_ON_LARGE_FILES="true";;
		*)  echo "Wrong option";
			exit 111;;
    esac
done 

MYCAT="${RUNNER} mycat"

CURRENT_PATH=`pwd`
PATH=$PATH:$CURRENT_PATH 
ERRORS_FILE=mycat_errors.txt
EXPECTED_ERRORS_FILE=mycat_expected_errors.txt
SINGLE_FILE=books1-10.txt
SINGLE_FILE_HEX=hexified_books1-10.txt
FILE_LIST1="book1.txt book2.txt"
FILE_LIST1_HEX="hexified_book1.txt hexified_book2.txt"
FILE_LIST2="book1.txt book2.txt book3.txt book4.txt book5.txt"
FILE_LIST2a="book1.txt -A book2.txt book3.txt book4.txt book5.txt"
FILE_LIST2b="book1.txt book2.txt -A book3.txt book4.txt book5.txt"
FILE_LIST2c="book1.txt book2.txt book3.txt -A book4.txt book5.txt"
FILE_LIST2_HEX="hexified_book1.txt hexified_book2.txt hexified_book3.txt hexified_book4.txt hexified_book5.txt"
FILE_EXREALARGE_ROUGHLY_1GB="extra_large_0.txt"
FILE_EXREALARGE_LESS_2GB="extra_large_1.txt"
FILE_EXREALARGE_MORE_4GB="extra_large_2.txt"

rm -f $ERRORS_FILE $EXPECTED_ERRORS_FILE

echo "Base check -- 1"
${MYCAT} $SINGLE_FILE > out_$SINGLE_FILE 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed base check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

diff $SINGLE_FILE out_$SINGLE_FILE >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of base test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

echo "Base check -- 2, absolute path"
${MYCAT} $CURRENT_PATH/$SINGLE_FILE > $CURRENT_PATH/out_$SINGLE_FILE 2>>$CURRENT_PATH/$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed base check 2"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

diff $CURRENT_PATH/$SINGLE_FILE $CURRENT_PATH/out_$SINGLE_FILE >> $CURRENT_PATH/$ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of base test 2"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

echo "Base check -- 3, relative path"
mkdir t -p
cd t
${MYCAT} ../$SINGLE_FILE >  ../out_$SINGLE_FILE 2>>../$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed base check 3"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff  ../$SINGLE_FILE  ../out_$SINGLE_FILE >>../$ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of base test 3"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

cd $CURRENT_PATH 
rm ./t -r

echo "Base check -- 4, -A"
${MYCAT} -A $SINGLE_FILE >  out_$SINGLE_FILE 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed base check 4"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff  $SINGLE_FILE_HEX out_$SINGLE_FILE >>$ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of base test 4"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi


#=================================================
echo "Two files -- 1"
${MYCAT} $FILE_LIST1 > out_test2.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed two files 1 check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

cat $FILE_LIST1 > etalon_test2.txt 

diff out_test2.txt etalon_test2.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of two files 1 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

echo "Two files -- 2, -A"
${MYCAT} -A $FILE_LIST1 > out_test2.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed two files 2 check "
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

cat $FILE_LIST1_HEX > etalon_test2.txt 

diff out_test2.txt etalon_test2.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of two files 2 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

echo "Two files -- 3, -A"
${MYCAT} $FILE_LIST1 -A > out_test2.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed two files 3 check "
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

cat $FILE_LIST1_HEX > etalon_test2.txt 

diff out_test2.txt etalon_test2.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of two files 3 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi
#=================================================
echo "Five files -- 1"
${MYCAT} $FILE_LIST2 > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 1 check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

cat $FILE_LIST2 > etalon_test5.txt 

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 1 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

echo "Five files -- 2, -A"
${MYCAT} -A $FILE_LIST2 > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 2 check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

cat $FILE_LIST2_HEX > etalon_test5.txt 

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 2 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

echo "Five files -- 3, -A"
${MYCAT} $FILE_LIST2 -A > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 3 check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 3 test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

echo "Five files -- 4, -A"
${MYCAT} $FILE_LIST2a > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 4a check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 4a test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

${MYCAT} $FILE_LIST2b > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 4b check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 4b test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

${MYCAT} $FILE_LIST2c > out_test5.txt 2>>$ERRORS_FILE
if [[ $? -ne 0 ]]; then
	echo "Failed five files 4c check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

diff out_test5.txt etalon_test5.txt >> $ERRORS_FILE 2>&1
if [[ $? -ne 0 ]]; then
	echo "Wrong result of five files 4c test"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi

fi

#=================================================
if [ "$TEST_ON_LARGE_FILES" = "true" ]; then
	echo "Checking on extra-large files."

	echo "Running time for ~1Gb file."
	( time ${MYCAT} $FILE_EXREALARGE_ROUGHLY_1GB > out_$SINGLE_FILE 2>>$ERRORS_FILE ) 2> stats_own.txt
	if [[ $? -ne 0 ]]; then
		echo "Failed extra-large file (~1Gb) check"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi
	echo "\tComparing runtime..."

	( time cat $FILE_EXREALARGE_ROUGHLY_1GB > out_$SINGLE_FILE 2>>$ERRORS_FILE ) 2> stats_sys.txt

	own_time_str=$(cat stats_own.txt | grep -e "real" | sed -E 's/real[[:space:]]*([0-9]+)m([0-9]+),([0-9]+)s/\1 \2 \3/')
	read mins secs millis <<< "$own_time_str"
	total_own_ms=$(( mins*60000 + secs*1000 + millis ))

	sys_time_str=$(cat stats_sys.txt | grep -e "real" | sed -E 's/real[[:space:]]*([0-9]+)m([0-9]+),([0-9]+)s/\1 \2 \3/')
	read mins secs millis <<< "$sys_time_str"
	total_sys_ms=$(( mins*60000 + secs*1000 + millis ))

	rm stats_own.txt stats_sys.txt

	if [[ $total_own_ms -gt $(( 2 * $total_sys_ms )) ]]; then
		echo "Error. The runtime for ~1Gb file is larger than twice the runtime of the system 'cat'!"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi

	echo "Less than 2Gb."
	${MYCAT} $FILE_EXREALARGE_LESS_2GB > out_$SINGLE_FILE 2>>$ERRORS_FILE
	if [[ $? -ne 0 ]]; then
		echo "Failed extra-large file (<2Gb) check"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi
	echo "\tComparing"
	diff $FILE_EXREALARGE_LESS_2GB out_$SINGLE_FILE >> $ERRORS_FILE 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Wrong result of extra-large file (<2Gb) test"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi
	rm out_$SINGLE_FILE
	
	echo "More than 4Gb."
	${MYCAT} $FILE_EXREALARGE_MORE_4GB > out_$SINGLE_FILE 2>>$ERRORS_FILE
	if [[ $? -ne 0 ]]; then
		echo "Failed extra-large file (>4Gb) check"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi
	echo "\tComparing"
	diff $FILE_EXREALARGE_MORE_4GB out_$SINGLE_FILE >> $ERRORS_FILE 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Wrong result of extra-large file (>4Gb) test"
		if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
			exit 1
		fi
	fi
	rm out_$SINGLE_FILE
fi

#=================================================
echo "Checking for expected errors"

echo "Check for nonexistent file " >> $EXPECTED_ERRORS_FILE
ABSENT=nunematakogofile.txt
if [ -f $ABSENT ]; then
	rm -f $ABSENT 
fi	
${MYCAT} "nunematakogofile.txt" >$EXPECTED_ERRORS_FILE 2>&1
if [[ $? -eq 0 ]]; then
	echo "Wrong result of nonexistent file check"
	if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
		exit 1
	fi
fi

#=================================================

if [ "$EXIT_ON_FIRST_ERROR" = "true" ]; then
	echo "All OK"	
else	
	echo "Finished"
fi
exit 0
