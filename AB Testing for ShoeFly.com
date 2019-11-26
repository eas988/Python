import codecademylib
import pandas as pd

ad_clicks = pd.read_csv('ad_clicks.csv')

#Examine first few rows of ad_clicks
print(ad_clicks.head())

#HWhich ad platform is getting us the most views?
ad_source = ad_clicks.groupby('utm_source').user_id.count().reset_index()

#If ad_click_timestamp is not null, someone actually clicked the ad.
ad_clicks['is_click'] = ~ad_clicks.ad_click_timestamp.isnull()

#What percentage of people clicked on ads from each source?
clicks_by_source = ad_clicks.groupby(['utm_source', 'is_click']).user_id.count().reset_index()

#Pivot so columns are is_click, index is utm_source, and values are user_id
clicks_pivot = clicks_by_source.pivot(columns='is_click',
                                     index='utm_source',
                                     values='user_id')
                                     
#Create new column in clicks_pivot equal to percent of users who clicked on the ad from each utm_source
clicks_pivot['percent_clicked'] = clicks_pivot[True] / (clicks_pivot[True]+clicks_pivot[False]) * 100

#How many people were shown each ad type?
experimental = ad_clicks.groupby(['experimental_group']).user_id.count()

#Check which population of users clicked on ad A or ad B
clicked = ad_clicks.groupby(['is_click', 'experimental_group']).user_id.count().reset_index()
clicked_pivot = clicked.pivot(columns='experimental_group',
                              index='is_click',
                              values='user_id')
                              
#Create two DataFrames that contain only results from each targeted ad type
a_clicks = ad_clicks[ad_clicks.experimental_group == 'A']
b_clicks =ad_clicks[ad_clicks.experimental_group == 'B']

#For each group, calculate percentage of users who clicked on each ad by day
a_clicks_by_day = a_clicks.groupby(['day', 'is_click']).user_id.count().reset_index()
a_by_day_pivot = a_clicks_by_day.pivot(columns='is_click',
                                      index='day',
                                      values='user_id')
a_by_day_pivot['percent_clicked_this_day'] = (a_by_day_pivot[True] / \
    (a_by_day_pivot[True]+a_by_day_pivot[False]) * 100).round(2)
b_clicks_by_day = b_clicks.groupby(['day', 'is_click']).user_id.count().reset_index()
b_by_day_pivot = b_clicks_by_day.pivot(columns='is_click',
                                      index='day',
                                      values='user_id')
b_by_day_pivot['percent_clicked_this_day'] = (b_by_day_pivot[True] / \
    (b_by_day_pivot[True]+b_by_day_pivot[False]) * 100).round(2)
    
#Compare and recommend an ad based on the results.
print(a_by_day_pivot)
print(b_by_day_pivot)
#Ad A was more successful every single day of the week except on Tuesday, and on that day only barely
