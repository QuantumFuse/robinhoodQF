### robinhoodQF

``` r
source("functions.R") ### to be replaced with library(robinhoodQF)
```

### Login

With Robinhood's recent modicification to their public API, accessing data now requires authorization headers and tokens that need to be generated using existing account credentials. The access\_robinhood uses account credentials to create the required authorization headers and tokens; however, account credentials are removed from the system memory immediately after all required authorization is created.

``` r
access_robinhood(username="username", password="password")
```

The access\_robinhood function will create a list called robinhoodUser, containing two R6 classes that underly most global methods in the robinhoodQF package. The robindhoodQF package is designed so that you will never need to directly interact with this list or its contents.

### Historical Data

The robinhoodQF package allows you to download the last year of daily data, as well as the last week of 5 minute tick data, from the Robinhood API for a list of shorthand ticker symbols:

``` r
library(formattable)
source("stock_formattable.R")
mySymbols <- c("AAPL","AMZN")
dailyData <- robinhood_daily_historicals(symbols=mySymbols)
intradayData <- robinhood_intraday_historicals(symbols=mySymbols)
dailyData$AAPL%>%head()%>%as.data.frame()%>%make_stock_formattable()
```

<table class="table table-condensed">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:right;">
open
</th>
<th style="text-align:right;">
high
</th>
<th style="text-align:right;">
low
</th>
<th style="text-align:right;">
close
</th>
<th style="text-align:right;">
volume
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2018-02-21
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 172.83</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 174.12</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.01</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 171.07</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">37471623</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-22
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.80</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 173.95</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.71</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 172.50</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">30991940</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-23
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 173.67</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 175.65</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 173.54</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 175.50</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">33812360</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-26
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 176.35</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 179.39</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 176.21</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 178.97</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">38162174</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-27
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 179.10</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 180.48</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 178.16</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 178.39</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">38928125</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-28
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 179.26</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 180.62</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 178.05</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 178.12</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">37782138</span>
</td>
</tr>
</tbody>
</table>
``` r
dailyData$AMZN%>%head()%>%as.data.frame()%>%make_stock_formattable()
```

<table class="table table-condensed">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:right;">
open
</th>
<th style="text-align:right;">
high
</th>
<th style="text-align:right;">
low
</th>
<th style="text-align:right;">
close
</th>
<th style="text-align:right;">
volume
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2018-02-21
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,485.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,503.49</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,478.92</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,482.92</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">6304351</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-22
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,495.36</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,502.54</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,475.76</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,485.34</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">4858063</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-23
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,495.34</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,500.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,486.50</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 1,500.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">4418103</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-26
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,509.20</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,522.84</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,507.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 1,521.95</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">4954988</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-27
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,524.50</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,526.78</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,507.21</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,511.98</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">4808776</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2018-02-28
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,519.51</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,528.70</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,512.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,512.45</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">4515023</span>
</td>
</tr>
</tbody>
</table>
``` r
intradayData$AAPL%>%head()%>%as.data.frame()%>%make_stock_formattable()
```

<table class="table table-condensed">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:right;">
open
</th>
<th style="text-align:right;">
high
</th>
<th style="text-align:right;">
low
</th>
<th style="text-align:right;">
close
</th>
<th style="text-align:right;">
volume
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2019-02-15 14:30:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.22</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.70</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 171.13</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">2412697</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:35:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.13</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.23</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.49</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 171.06</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">273892</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:40:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.08</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 171.08</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.34</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 170.37</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">230501</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:45:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.40</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.85</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.13</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 170.22</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">279939</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:50:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.19</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.20</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 169.76</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 169.92</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">363468</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:55:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 169.92</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 170.56</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 169.91</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 170.46</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">223322</span>
</td>
</tr>
</tbody>
</table>
``` r
intradayData$AMZN%>%head()%>%as.data.frame()%>%make_stock_formattable()
```

<table class="table table-condensed">
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:right;">
open
</th>
<th style="text-align:right;">
high
</th>
<th style="text-align:right;">
low
</th>
<th style="text-align:right;">
close
</th>
<th style="text-align:right;">
volume
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2019-02-15 14:30:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,627.09</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,628.91</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,621.51</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,622.34</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">233071</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:35:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,621.62</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,622.55</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,615.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,620.22</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">46206</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:40:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,620.20</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,620.20</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,613.99</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,614.54</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">41530</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:45:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,615.33</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,620.49</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,614.21</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #66b266">$ 1,615.54</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">32880</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:50:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,615.59</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,615.59</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,612.00</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,612.68</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">31449</span>
</td>
</tr>
<tr>
<td style="text-align:left;">
2019-02-15 14:55:00
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,612.49</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,615.59</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">$ 1,611.69</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: white; background-color: #FF6666">$ 1,612.26</span>
</td>
<td style="text-align:right;">
<span style="display: block; border-radius: 1px; padding-right: 1px; color: black; background-color: white">27608</span>
</td>
</tr>
</tbody>
</table>
### Charting

The robinhoodQF package allows you to build interactive plotly charts for visualizing price series and plotting technical indicators.

``` r
myChart <- create_chart(tickerSymbol="AAPL", ohlcvData=dailyData$AAPL)
myChart$create_plot("candlestick")

## plot just closing prices
p1<-myChart$pricePlot
tmpFile1 <- tempfile(fileext = ".png")
export(p1, file = tmpFile1)
```

![](README_files/figure-markdown_github/unnamed-chunk-4-1.png)

``` r
## plot closing prices with volume
p2<-myChart$volumeCombinedPlot
tmpFile2 <- tempfile(fileext = ".png")
export(p2, file = tmpFile2)
```

![](README_files/figure-markdown_github/unnamed-chunk-4-2.png)

### Account Information

``` r
get_watchlist_tickers()
```

    ##  [1] "TQQQ" "LOGC" "MGTX" "AVRO" "ORTX" "SPXS" "VIXY" "VXX"  "TSRO" "QQQ" 
    ## [11] "ALL"  "MXIM" "SPY"  "CELG" "MRO"  "AAL"  "DLTR" "JPM"  "BK"   "GOOG"
    ## [21] "MA"   "PGR"  "ATHX" "CHK"  "TWOU" "C"    "BA"   "CRM"  "FLO"  "WMT" 
    ## [31] "ARKR" "IZRL" "ARKQ" "ARKG" "ARKW" "ARKK" "APPN" "SGH"  "WDC"  "OLED"
    ## [41] "OKTA" "DBX"  "KEM"  "NVDA" "MOMO" "ICHR" "ABT"  "NFLX" "HIMX" "LRCX"
    ## [51] "BZUN" "FB"   "YY"   "ABBV" "AAOI" "VZ"   "SMI"  "SODA" "BAC"  "TSM" 
    ## [61] "SNAP" "SQ"   "TXN"  "AMD"  "ACLS" "INTC" "ASX"  "MCHP" "MU"   "ON"  
    ## [71] "AMAT" "CSCO" "AKAM" "MLNX" "QCOM" "AGNC" "AAPL" "F"    "OCSL" "KO"

``` r
holdings<-get_equity_holdings()
holdings$table
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":[""],"name":["_rn_"],"type":[""],"align":["left"]},{"label":["name"],"name":[1],"type":["chr"],"align":["left"]},{"label":["quantity"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["average_price"],"name":[3],"type":["dbl"],"align":["right"]}],"data":[{"1":"Cosan Limited","2":"30","3":"10.6600","_rn_":"CZZ"},{"1":"iShares Core MSCI Emerging Markets ETF","2":"20","3":"49.9320","_rn_":"IEMG"},{"1":"ProShares UltraPro Short QQQ","2":"18","3":"11.8943","_rn_":"SQQQ"},{"1":"Financial Select Sector SPDR Fund","2":"35","3":"28.0900","_rn_":"XLF"},{"1":"Amazon.com, Inc. Common Stock","2":"1","3":"1636.5000","_rn_":"AMZN"},{"1":"Microsoft Corporation Common Stock","2":"10","3":"104.2407","_rn_":"MSFT"},{"1":"Alibaba Group Holding Limited","2":"3","3":"166.6572","_rn_":"BABA"},{"1":"VISA Inc.","2":"7","3":"135.2506","_rn_":"V"},{"1":"Nutanix, Inc. Class A Common Stock","2":"10","3":"50.1627","_rn_":"NTNX"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

``` r
holdings$tickers
```

    ##  [1] "XBI"  "CZZ"  "IEMG" "SQQQ" "XLF"  "AMZN" "MSFT" "BABA" "V"    "NTNX"

``` r
robinhoodUser$account$positionsTable
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":[""],"name":["_rn_"],"type":[""],"align":["left"]},{"label":["name"],"name":[1],"type":["chr"],"align":["left"]},{"label":["quantity"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["average_price"],"name":[3],"type":["dbl"],"align":["right"]}],"data":[{"1":"SPDR S&P Biotech ETF","2":"6","3":"79.9600","_rn_":"XBI"},{"1":"Cosan Limited","2":"30","3":"10.6600","_rn_":"CZZ"},{"1":"iShares Core MSCI Emerging Markets ETF","2":"20","3":"49.9320","_rn_":"IEMG"},{"1":"ProShares UltraPro QQQ","2":"0","3":"0.0000","_rn_":"TQQQ"},{"1":"LogicBio Therapeutics, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"LOGC"},{"1":"MeiraGTx Holdings plc Ordinary Shares","2":"0","3":"0.0000","_rn_":"MGTX"},{"1":"AVROBIO, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AVRO"},{"1":"Orchard Therapeutics plc American Depositary Shares","2":"0","3":"0.0000","_rn_":"ORTX"},{"1":"Direxion Daily S&P 500 Bear 3x Shares","2":"0","3":"0.0000","_rn_":"SPXS"},{"1":"ProShares UltraPro Short QQQ","2":"18","3":"11.8943","_rn_":"SQQQ"},{"1":"ProShares VIX Short-Term Futures ETF","2":"0","3":"0.0000","_rn_":"VIXY"},{"1":"iPath S&P 500 VIX Short-Term Futures ETN due 1/30/2019","2":"0","3":"0.0000","_rn_":"VXX"},{"1":"TESARO, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"TSRO"},{"1":"Financial Select Sector SPDR Fund","2":"35","3":"28.0900","_rn_":"XLF"},{"1":"Invesco QQQ Trust, Series 1","2":"0","3":"0.0000","_rn_":"QQQ"},{"1":"The Allstate Corporation","2":"0","3":"0.0000","_rn_":"ALL"},{"1":"Maxim Integrated Products, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"MXIM"},{"1":"SPDR S&P 500 ETF Trust","2":"0","3":"0.0000","_rn_":"SPY"},{"1":"Celgene Corporation Common Stock","2":"0","3":"0.0000","_rn_":"CELG"},{"1":"Marathon Oil Corporation","2":"0","3":"0.0000","_rn_":"MRO"},{"1":"American Airlines Group Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AAL"},{"1":"Dollar Tree Inc. Common Stock","2":"0","3":"0.0000","_rn_":"DLTR"},{"1":"JPMorgan Chase & Co.","2":"0","3":"0.0000","_rn_":"JPM"},{"1":"Bank of New York Mellon Corporation","2":"0","3":"0.0000","_rn_":"BK"},{"1":"Alphabet Inc. Class C Capital Stock","2":"0","3":"0.0000","_rn_":"GOOG"},{"1":"Mastercard Incorporated","2":"0","3":"0.0000","_rn_":"MA"},{"1":"Progressive Corporation","2":"0","3":"0.0000","_rn_":"PGR"},{"1":"Athersys, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"ATHX"},{"1":"Amazon.com, Inc. Common Stock","2":"1","3":"1636.5000","_rn_":"AMZN"},{"1":"Chesapeake Energy Corp.","2":"0","3":"0.0000","_rn_":"CHK"},{"1":"2U, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"TWOU"},{"1":"Citigroup Inc.","2":"0","3":"0.0000","_rn_":"C"},{"1":"Boeing Company","2":"0","3":"0.0000","_rn_":"BA"},{"1":"salesforce.com, inc.","2":"0","3":"0.0000","_rn_":"CRM"},{"1":"Flowers Foods, Inc.","2":"0","3":"0.0000","_rn_":"FLO"},{"1":"Walmart Inc.","2":"0","3":"0.0000","_rn_":"WMT"},{"1":"Microsoft Corporation Common Stock","2":"10","3":"104.2407","_rn_":"MSFT"},{"1":"Ark Restaurants Corp. Common Stock","2":"0","3":"0.0000","_rn_":"ARKR"},{"1":"ARK Israel Innovative Technology ETF","2":"0","3":"0.0000","_rn_":"IZRL"},{"1":"ARK Industrial Innovation ETF","2":"0","3":"0.0000","_rn_":"ARKQ"},{"1":"ARK Genomic Revolution Multi-Sector ETF","2":"0","3":"0.0000","_rn_":"ARKG"},{"1":"ARK Web x.0 ETF","2":"0","3":"0.0000","_rn_":"ARKW"},{"1":"ARK Innovation ETF","2":"0","3":"0.0000","_rn_":"ARKK"},{"1":"Appian Corporation Class A Common Stock","2":"0","3":"0.0000","_rn_":"APPN"},{"1":"SMART Global Holdings, Inc. Ordinary Shares","2":"0","3":"0.0000","_rn_":"SGH"},{"1":"Western Digital Corporation Common Stock","2":"0","3":"0.0000","_rn_":"WDC"},{"1":"Universal Display Corporation Common Stock","2":"0","3":"0.0000","_rn_":"OLED"},{"1":"Okta, Inc. Class A Common Stock","2":"0","3":"0.0000","_rn_":"OKTA"},{"1":"Dropbox, Inc. Class A Common Stock","2":"0","3":"31.5000","_rn_":"DBX"},{"1":"KEMET Corporation","2":"0","3":"0.0000","_rn_":"KEM"},{"1":"NVIDIA Corporation Common Stock","2":"0","3":"0.0000","_rn_":"NVDA"},{"1":"Momo Inc. American Depositary Shares","2":"0","3":"0.0000","_rn_":"MOMO"},{"1":"Ichor Holdings Ordinary Shares","2":"0","3":"0.0000","_rn_":"ICHR"},{"1":"Abbott Laboratories","2":"0","3":"58.6900","_rn_":"ABT"},{"1":"Netflix, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"NFLX"},{"1":"Himax Technologies, Inc. American Depositary Shares","2":"0","3":"7.1700","_rn_":"HIMX"},{"1":"Lam Research Corporation Common Stock","2":"0","3":"0.0000","_rn_":"LRCX"},{"1":"Baozun Inc. American Depositary Shares","2":"0","3":"0.0000","_rn_":"BZUN"},{"1":"Facebook, Inc. Class A Common Stock","2":"0","3":"0.0000","_rn_":"FB"},{"1":"YY Inc. American Depositary Shares","2":"0","3":"96.1200","_rn_":"YY"},{"1":"ABBVIE INC.","2":"0","3":"99.3200","_rn_":"ABBV"},{"1":"Applied Optoelectronics, Inc. Common Stock","2":"0","3":"31.8500","_rn_":"AAOI"},{"1":"Verizon Communications","2":"0","3":"49.5500","_rn_":"VZ"},{"1":"Alibaba Group Holding Limited","2":"3","3":"166.6572","_rn_":"BABA"},{"1":"Semiconductor Manufacturing International Corporation","2":"0","3":"0.0000","_rn_":"SMI"},{"1":"SodaStream International Ltd. Ordinary Shares","2":"0","3":"97.4200","_rn_":"SODA"},{"1":"VISA Inc.","2":"7","3":"135.2506","_rn_":"V"},{"1":"Bank of America Corporation","2":"0","3":"0.0000","_rn_":"BAC"},{"1":"Taiwan Semiconductor Manufacturing Company Ltd.","2":"0","3":"0.0000","_rn_":"TSM"},{"1":"Snap Inc.","2":"0","3":"0.0000","_rn_":"SNAP"},{"1":"Square, Inc.","2":"0","3":"0.0000","_rn_":"SQ"},{"1":"Nutanix, Inc. Class A Common Stock","2":"10","3":"50.1627","_rn_":"NTNX"},{"1":"Texas Instruments Incorporated Common Stock","2":"0","3":"104.9200","_rn_":"TXN"},{"1":"Advanced Micro Devices, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AMD"},{"1":"Axcelis Technologies, Inc. Common Stock","2":"0","3":"24.7500","_rn_":"ACLS"},{"1":"Intel Corporation Common Stock","2":"0","3":"0.0000","_rn_":"INTC"},{"1":"Advanced Semiconductor","2":"0","3":"0.0000","_rn_":"ASX"},{"1":"Microchip Technology Incorporated Common Stock","2":"0","3":"93.6500","_rn_":"MCHP"},{"1":"Micron Technology, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"MU"},{"1":"ON Semiconductor Corporation Common Stock","2":"0","3":"25.8100","_rn_":"ON"},{"1":"Applied Materials, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AMAT"},{"1":"Cisco Systems, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"CSCO"},{"1":"Akamai Technologies, Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AKAM"},{"1":"Mellanox Technologies, Ltd. Ordinary Shares","2":"0","3":"84.8000","_rn_":"MLNX"},{"1":"QUALCOMM Incorporated Common Stock","2":"0","3":"0.0000","_rn_":"QCOM"},{"1":"AGNC Investment Corp. Common Stock","2":"0","3":"18.8400","_rn_":"AGNC"},{"1":"Apple Inc. Common Stock","2":"0","3":"0.0000","_rn_":"AAPL"},{"1":"Ford Motor Company","2":"0","3":"0.0000","_rn_":"F"},{"1":"Oaktree Specialty Lending Corporation Common Stock","2":"0","3":"4.3500","_rn_":"OCSL"},{"1":"Coca-Cola Company","2":"0","3":"44.4700","_rn_":"KO"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

``` r
robinhoodUser$account$optionsPositionsTable
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["ticker"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["quantity"],"name":[2],"type":["fctr"],"align":["left"]},{"label":["type"],"name":[3],"type":["fctr"],"align":["left"]},{"label":["price"],"name":[4],"type":["dbl"],"align":["right"]}],"data":[{"1":"SQQQ","2":"1.0000","3":"long","4":"106"},{"1":"SQQQ","2":"1.0000","3":"long","4":"159"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

``` r
robinhoodUser$account$portfolioEquity
```

    ## NULL
