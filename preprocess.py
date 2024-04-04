import pandas as pd

df = pd.read_stata("data/ml_data.dta")
df["a_women"] = (df["Gender"] == "Female").astype(int)
women_by_hh = df.groupby("Common_ID")["a_women"].sum()
women_by_hh.name = "t_a_women"
df = df.merge(women_by_hh, left_on="Common_ID", right_index=True)
df["t_add_women"] = df["t_a_women"] - 1
df.rename(
    {
        "t_child": "Total Children in HH",
        "t_a_women": "Total Women in HH",
        "t_add_women": "Total Additional Women in HH",
    },
    axis=1,
    inplace=True,
)


# Encode employment status
def enc_usual_principal_activity(val):
    if val < 31:
        return "Self-Employed"
    if val == 31:
        return "Salaried Employee"
    if val in [41, 51]:
        return "Casual Labour"
    if val >= 81:
        return "Not Employed"
    return "EMP NA"


df["employment"] = (
    df["usual_principal_activity__status"]
    .map(enc_usual_principal_activity)
    .astype("category")
)
df["employment"] = df["employment"].cat.reorder_categories(
    ["Not Employed", "Self-Employed", "Salaried Employee", "Casual Labour"],
    ordered=True,
)
df = df[df["Age"] >= 15]

marital_status = {
    1: "Never Married",
    2: "Currently Married",
    3: "Widowed",
    4: "Divorced",
}
df["marital_status"] = df["marital_status"].replace(marital_status).astype("category")
df["marital_status"] = df["marital_status"].cat.reorder_categories(
    ["Never Married", "Currently Married", "Widowed", "Divorced"], ordered=True
)

COLS = ["Age", "Gender", "state_codes"]
COLS.extend(
    ["Total Children in HH", "Total Women in HH", "Total Additional Women in HH"]
)
# COLS.extend(["paid_activity_time", "unpaid_activity_time"])
COLS.append("education")
COLS.append("marital_status")
COLS.append("employment")
COLS.append("Social_group_")
COLS.append("religion")
df["sector"].replace({1.0: "Rural", 2.0: "Urban"}, inplace=True)
COLS.append("sector")
COLS.append("MPCE_qrt")
COLS.append("piped_gas")
COLS.extend(["wired_source", "washing_type", "sweeeping_type"])
COLS.extend(["child", "old", "n_unemp_men", "employed_help", "old_child"])
COLS.append("pweight")

# Adding other columns that were excluded accidentally
COLS.extend(['special_need', 'n_working_women'])

target_cols = [
    "paid_activity_time",
    "unpaid_activity_time",
    "leisure_time",
    "cooking_time",
    "cleaning_time",
    "firewood_time",
    "washing_time",
    "hh_time",
    "care_time",
]
target_names = [
    "Time Spent on Paid Work",
    "Time Spent on Unpaid Work",
    "Time Spent on Leisure",
    "Time Spent Cooking",
    "Time Spent Cleaning",
    "Time Spent Collecting Firewood",
    "Time Spent Washing",
    "Time Spent on Domestic Chores",
    "Time Spent on Care Work",
]
mapper = {k: v for k, v in zip(target_cols, target_names)}
df.rename(mapper, axis=1, inplace=True)
COLS.extend(mapper.values())
df[COLS].to_csv("data/models_data5.csv", index=False)
