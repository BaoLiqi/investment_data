import tushare as ts
import os
import datetime
import pandas
import fire
import time
import datetime

ts.set_token(os.environ["TUSHARE"])
pro=ts.pro_api()
file_path = os.path.dirname(os.path.realpath(__file__))

index_list = [
    '000905.SH', # csi500
    '399300.SZ'  # csi300
    ]

def dump_index_data(start_date=None, end_date=None, skip_exists=True):
    
    for index_name in index_list:
        time_step = datetime.timedelta(days=15)
        if start_date is None:
            index_info = pro.index_basic(ts_code=index_name)
            list_date = index_info["list_date"][0]
            list_date_obj = datetime.datetime.strptime(list_date, '%Y%m%d')
            index_start_date = list_date_obj
        else:
            index_start_date = datetime.datetime.strptime(str(start_date), '%Y%m%d')
        
        if end_date is None:
            index_end_date = list_date_obj + time_step
        else:
            index_end_date = datetime.datetime.strptime(str(end_date), '%Y%m%d')

        filename = f'{file_path}/index_weight/{index_name}.csv'
        print("Dump to: ", filename)
        result_df_list = []
        while index_end_date < datetime.datetime.now():
            df = pro.index_weight(index_code=index_name, start_date = index_start_date.strftime('%Y%m%d'), end_date=index_end_date.strftime('%Y%m%d'))
            result_df_list.append(df)
            index_start_date += time_step
            index_end_date += time_step
            time.sleep(0.5)
        result_df = pandas.concat(result_df_list)
        result_df["stock_code"] = result_df["con_code"]
        result_df.to_csv(filename, index=False)

if __name__ == '__main__':
    fire.Fire(dump_index_data)
