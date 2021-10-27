import logging
import csv
import datetime
from itertools import islice

logger = logging.getLogger(__name__)


class ProcessFile():
    def __init__(self, etl_params: dict):
        """
        The input_* variables are used for reading the file (all are optional)
        The output_* variables are used for modifying the output (all are optional)
        User, system and datetime parameters are stored in the dictionary: etl_params
        eg: access your own parameters with etl_params['my_own_user_param']
        """
        self.etl_params = etl_params

        self.input_encoding = 'latin1'
        self.input_mode = 'rt'  # Used in the open() file method. So can also be 'rb' or 'rU'.

        self.output_file_nm = '{source_file_nm_without_ext}_{task_detail_log_id}.csv'.format(**etl_params)
        self.output_delimiter = ';'
        self.output_encoding = self.input_encoding

    def run(self, f):
        """
        f is of type str when self.input_mode = 'b'
        f is of type generator when self.input_mode = 't'
        function run should return un iterable. eg: a list or a tuple
        """
        csv_reader = csv.reader(f)   #, delimiter=';', quotechar='"')

        prepend_info = []

        for no, row in enumerate(csv_reader):
            print(f'zz {row}')
            yield row

# Below a method to invoke the above script on your local machine.
# PLEASE DO NOT COPY THE BELOW SCRIPT INTO PROD
if __name__ == "__main__":
    p = ProcessFile({'schema_nm': 'dummy_schema_nm',
                     'account_nm': 'dummy_account_nm',
                     'folder_nm': 'dummy_folder',
                     'run_dt': datetime.datetime.now(),
                     'source_file_nm_without_ext': 'source_file_nm',
                     'source_file_nm': 'source_file_nm.xls',
                     'task_detail_log_id': 999})
    for li, line in enumerate(p.run(open('/Users/maartenzaanen/Downloads/FactuurbestandPIFHDAC.20201201000000.20201231235959.EXP', 'r').readline())):
        print(line)
        if li > 10:
            break


# from csv import reader
# # open file in read mode
# with open('/Users/maartenzaanen/Downloads/FactuurbestandPIFHDAC.20201201000000.20201231235959.EXP', 'r') as read_obj:
#     # pass the file object to reader() to get the reader object
#     csv_reader = reader(read_obj)
#     # Iterate over each row in the csv using reader object
#     for li, row in enumerate(csv_reader):
#         # row variable is a list that represents a row in csv
#         print(row)
#         if li > 10:
#             break

<HASH:0xE7C0FB1ACCFF12EAC61770EEFE53A65EF9CBFE32>
290005;0504712;43363;01.01.2021;"EUR"
0;"Entrepotdok I";21;"Inrit SG 8101";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 12:51:10;0;0,00
0;"Entrepotdok I";41;"Uitrit SG 8102";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 12:52:17;2;0,00
0;"Entrepotdok III";21;"Inrit SG 8121";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 12:55:14;0;0,00
0;"Entrepotdok III";41;"Uitrit SG 8122";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 12:56:17;2;0,00
0;"Entrepotdok II";21;"Inrit SG 8111";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 13:58:39;0;0,00
0;"Entrepotdok II";41;"Uitrit SG 8112";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:09:43;2;0,00
0;"Entrepotdok I";21;"Inrit SG 8101";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:25:35;0;0,00
0;"Entrepotdok I";41;"Uitrit SG 8102";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:26:17;2;0,00
0;"Entrepotdok I";21;"Inrit SG 8101";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:30:24;0;0,00
0;"Entrepotdok I";41;"Uitrit SG 8102";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:40:57;2;0,00
0;"Entrepotdok I";21;"Inrit SG 8101";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 14:41:46;0;0,00
0;"Entrepotdok I";41;"Uitrit SG 8102";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";02.12.2020 15:14:56;2;0,00
0;"Werfgarage";21;"Inrit SG 8161";"1";1;"Parkeergebouwen";1;"Lagcher";"07586780050471200000005";"";7;"Altijd Geldig";09.12.2020 10:23:39;0;0,00
0;"De Hallen";197;"Inrit 6611";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";03.12.2020 10:10:31;0;0,00
0;"De Hallen";198;"Uitrit 6621";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";03.12.2020 10:17:17;2;0,00
0;"Entrepotdok I";21;"Inrit SG 8101";"99999";99999;"SkiData Benelux B.V";2;"Loris";"06469792050634500000193";"";342;"Altijd Geldig Entrepdok1";17.12.2020 10:55:59;0;0,00
0;"De Hallen";197;"Inrit 6611";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";18.12.2020 12:15:08;0;0,00
0;"De Hallen";198;"Uitrit 6621";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";18.12.2020 12:20:38;2;0,00
0;"De Hallen";197;"Inrit 6611";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";18.12.2020 15:05:18;0;0,00
0;"De Hallen";198;"Uitrit 6621";"2";2;"Garageparkeren";2;"Dienstwagen VV-675-T";"05709659050514900009492";"";7;"Altijd Geldig";18.12.2020 15:07:31;2;0,00
0;"Hofgarage";21;"Inrit SG 8141";"99998";99998;"Skidata";2;"DIST";"07269439050630300000252";"";7;"Altijd Geldig";28.12.2020 09:43:24;0;0,00
0;"HAKFORT";41;"Uitrit SG 8002";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";01.12.2020 08:37:33;2;0,00
0;"HAKFORT";21;"Inrit SG 8001";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";01.12.2020 10:58:08;0;0,00
0;"HAKFORT";41;"Uitrit SG 8002";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";02.12.2020 06:04:56;2;0,00
0;"Stadhuis";219;"IN Rechts";"2";2;"Stadsdeel Centrum";3;"Stadsdeelcentrum";"08869075050195700000156";"";7;"Altijd Geldig";02.12.2020 15:24:45;0;0,00
0;"HAKFORT";21;"Inrit SG 8001";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";02.12.2020 16:22:56;0;0,00
0;"Stadhuis";221;"UIT Rechts";"2";2;"Stadsdeel Centrum";3;"Stadsdeelcentrum";"08869075050195700000156";"";7;"Altijd Geldig";02.12.2020 22:17:53;2;0,00
0;"HAKFORT";41;"Uitrit SG 8002";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";03.12.2020 06:10:58;2;0,00
0;"HAKFORT";21;"Inrit SG 8001";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";03.12.2020 16:27:22;0;0,00
0;"HAKFORT";41;"Uitrit SG 8002";"1000";1;"Bewoners";3;"Kleijs";"07249369050628799002988";"";331;"Altijd Geldig Hakfort";04.12.2020 06:11:49;2;0,00
