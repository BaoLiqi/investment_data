set -e
set -x
WORKING_DIR=/content
QLIB_REPO=${2:-https://github.com/microsoft/qlib.git} 

if ! command -v dolt &> /dev/null
then
    curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | bash
fi

mkdir -p $WORKING_DIR/dolt

[ ! -d "$WORKING_DIR/dolt/investment_data" ] && cd $WORKING_DIR/dolt && dolt clone chenditc/investment_data
[ ! -d "$WORKING_DIR/qlib" ] && git clone $QLIB_REPO "$WORKING_DIR/qlib"

cd $WORKING_DIR/dolt/investment_data
dolt pull origin
dolt sql-server &

# wait for sql server start
sleep 5s

cd $WORKING_DIR/

mkdir -p ./qlib_dump/qlib_source
python3 ./qlib_dump/dump_all_to_qlib_source.py

export PYTHONPATH=$PYTHONPATH:$WORKING_DIR/qlib/scripts
python3 ./qlib_dump/normalize.py normalize_data --source_dir ./qlib_dump/qlib_source/ --normalize_dir ./qlib_dump/qlib_normalize --max_workers=16 --date_field_name="tradedate" 
python3 $WORKING_DIR/qlib/scripts/dump_bin.py dump_all --csv_path ./qlib_dump/qlib_normalize/ --qlib_dir $WORKING_DIR/qlib_bin --date_field_name=tradedate --exclude_fields=tradedate,symbol

mkdir -p ./qlib_dump/qlib_index/
python3 ./qlib_dump/dump_index_weight.py 
python3 ./tushare/dump_day_calendar.py $WORKING_DIR/qlib_bin/
killall dolt

cp ./qlib_dump/qlib_index/csi* $WORKING_DIR/qlib_bin/instruments/

tar -czvf ./qlib_bin.tar.gz $WORKING_DIR/qlib_bin/
ls -lh ./qlib_bin.tar.gz
