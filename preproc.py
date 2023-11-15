# coding: utf-8
import pandas as pd
from datetime import datetime

df = pd.read_csv("data/female_paid_activity.csv")
to_drop = [
    "Unnamed: 0",
    "index",
    "BYTES",
    "Filename",
    "Schedule_ID",
    "Schedule",
    "survey_year",
    "Common_ID",
    "Sample_hhld__No_",
    "Level",
    "Filler",
    "Serial_no_of_member",
    "Sub_Round",
    "srl__No_of_activity",
    "Blank",
    "iid",
    "mdivision",
    "division",
    "n_act",
    "Person_serial_no_",
    "Relation_to_head",
    "Gender",
    "Age",
    "women_working",
    "Old_child",
    "emp",
    "sna",
    "n_sna",
    "other",
    "prod_own_use",
    "hh",
    "care",
    "self_care",
    "paid_activity",
    "residual",
    "unemp_men",
    "imputed_value_of_usual_consumpti",
    "usual_consumer_expenditure_in_a_",
    "_0imputed_value_of_usual_consump",
    "expenditure_on_purchase_of_house",
    "state",
    "State_name",
]
td = df[["time_from", "time_to"]].apply(
    lambda x: datetime.strptime(x[1], "%H:%M") - datetime.strptime(x[0], "%H:%M"),
    axis=1,
)
df["time"] = td.dt.seconds / 3600
df.drop(["time_from", "time_to"], axis=1, inplace=True)
df["whether_performed_multiple_activ"] = (
    df["whether_performed_multiple_activ"].replace(" ", "0").astype(int)
)
df["whether_simultaneous_activity"] = (
    df["whether_simultaneous_activity"].replace(" ", "0").astype(int)
)
df["enterprise_type"] = df["enterprise_type"].replace(" ", "0").astype(int)

df.drop(["unpaid_activity_time", "care_time", "hh_time"], axis=1, inplace=True)
df.drop(to_drop, axis=1, inplace=True)
y = df.pop("paid_activity_time")
