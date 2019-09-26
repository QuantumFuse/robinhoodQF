import requests
import getpass
import pandas as pd
import numpy as np


class RhClient:

    def __init__(self, username):

        self.username = username
        self.headers = self.initHeaders()


    def login(self):

        authenticated = self.authenticate()
        self.headers['Authorization'] = authenticated['header']
        self.tokens = authenticated['tokens']


    def initHeaders(self):

        user_agents = [
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5)',
            'AppleWebKit/537.36 (KHTML, like Gecko)',
            'Chrome/75.0.3770.142 Safari/537.36'
        ]

        accepted_langs = [
            'en;q=1',
            'fr;q=0.9',
            'de;q=0.8',
            'ja;q=0.7',
            'nl;q=0.6',
            'it;q=0.5'
        ]

        to_return = dict()
        to_return['Accept'] = '*/*'
        to_return['Accept-Encoding'] = 'gzip, deflate'
        to_return['Accept-Language'] = ', '.join(accepted_langs)
        to_return['User-Agent'] = ' '.join(user_agents)

        return(to_return)


    def authenticate(self):

        oauth2 = 'https://api.robinhood.com/oauth2/token/'

        tokens = dict()
        tokens['grant_type'] = 'password'
        tokens['client_id'] = 'c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS'

        client = tokens.copy()
        client.update({'username': self.username, 'password': '{y}'})

        endpoint = ['='.join([attr, client[attr]]) for attr in list(client.keys())]
        endpoint = oauth2 + '?' + '&'.join(endpoint)

        req =  requests.post(endpoint.format(y=getpass.getpass(prompt='Password: ')))
        res = req.json()

        try:
            tokens.update({key: res[key] for key in ['access_token', 'refresh_token']})
        except:
            print('\nAuthentication Failed. Please check username and password.\n\n')

        authed = dict()
        authed['tokens'] = tokens
        authed['header'] = ' '.join([res['token_type'], res['access_token']])
        return(authed)






class RhETS:

    def __init__(self, headers, ticker):

        self.flattenList = lambda L: [x for y in L for x in y]
        self.which = lambda L, f: list(np.where([f(x) for x in L])).pop().tolist()
        self.chunkify = lambda L, n: [L[i:i+n] for i in range(0, len(L), n)]

        quotes_url = 'https://api.robinhood.com/quotes/'
        historicals_url = quotes_url + 'historicals/'
        instruments_url = 'https://api.robinhood.com/instruments/?symbol='

        self.ticker = ticker
        self.headers = headers
        self.get = lambda url, params=None: requests.get(url=url, headers = headers, params=params)

        self.historicals_endpoint = str().join([historicals_url, ticker]) + '/'
        self.instruments_endpoint = str().join([instruments_url, ticker])

        self.instrument = self.getInstrument()
        self.fundamentals = self.getFundamentals()
        self.tradable_chain_id = self.instrument['tradable_chain_id']
        self.quotes_endpoint = self.instrument['quote']
        self.splits_endpoint = self.instrument['splits']


    def getInstrument(self):

        res = self.get(self.instruments_endpoint).json()
        return(res['results'].pop())


    def getFundamentals(self):

        res = self.get(self.instrument['fundamentals']).json()
        return(res)


    def quote(self):

        res = self.get(self.quotes_endpoint).json()
        return(res)


    def historicals(self, interval='day'):

        if(isinstance(interval, int)):
            interval = str(interval) + 'minute'

        intraday_interval_opts = ['5minute', '10minute', '30minute', 'hour']
        span = 'week' if interval in intraday_interval_opts else 'year'
        params_dict = {'interval': interval, 'span':span, 'bounds':'regular'}
        res = self.get(self.historicals_endpoint, params=params_dict).json()

        return(res)


    def getContracts(self):

        contracts = list()
        next = 'https://api.robinhood.com/options/instruments/'
        params_dict = {
            'chain_id': self.tradable_chain_id,
            'rhs_tradability': 'tradable',
            'tradability': 'tradable',
            'state': 'active'
        }

        while(next is not None):

            res = self.get(next, params=params_dict).json()
            contracts.append(res['results'])
            next = res['next']

        to_return = pd.DataFrame(self.flattenList(contracts))
        self.options_expiries = list(np.unique(to_return['expiration_date']))
        return(to_return)


    def optionsChains(self):

        chains = dict()
        marketdata = dict()
        contracts = robinhood_ets.getContracts()
        options_marketdata_url = "https://api.robinhood.com/marketdata/options/"

        contracts = {
            'call': contracts.iloc[self.which(contracts['type'], lambda x: x=='call')],
            'put': contracts.iloc[self.which(contracts['type'], lambda x: x=='put')]
        }

        urls_dict = {key: contracts[key]['url'] for key in ['call', 'put']}
        urls_dict = {key: urls_dict[key].values.tolist() for key in ['call', 'put']}
        urls_dict = {key: self.chunkify(urls_dict[key], 50) for key in ['call', 'put']}
        urls_dict = {key: [','.join(x) for x in urls_dict[key]] for key in ['call', 'put']}

        for key in ['call', 'put']:

            temp_rows = list()

            for i in range(len(urls_dict[key])):

                temp_param_dict = {'instruments': urls_dict[key][i]}
                temp_res = self.get(options_marketdata_url, temp_param_dict).json()
                temp_rows.append(temp_res['results'])

            to_merge = pd.DataFrame(self.flattenList(temp_rows))
            marketdata[key] = pd.merge(contracts[key], to_merge, left_on='url', right_on='instrument')

        self.all_calls = marketdata['call']
        self.all_puts = marketdata['put']

        for expiry in self.options_expiries:

            chains[expiry] = dict()

            for key in ['call', 'put']:

                temp_indexes = marketdata[key]['expiration_date'].values.tolist()
                temp_indexes = self.which(temp_indexes, lambda x: x == expiry)
                chains[expiry][key] = marketdata[key].iloc[temp_indexes]

        self.options_chains = chains
        return(chains)




################################################################################
################################################################################

def rhMarketQuote(headers, tickers):

    quotes_endpoint = 'https://api.robinhood.com/quotes/?symbols='
    endpoint = str().join([quotes_endpoint, ','.join(tickers)])
    req = requests.get(endpoint, headers=headers)
    return(req.json())

################################################################################
################################################################################

# robinhood_client = RhClient('quantumfusetrader')
# robinhood_client.login()
#
# robinhood_ets = RhETS(robinhood_client.headers, 'AAPL')
# chains = robinhood_ets.optionsChains()
# chains
# robinhood_ets.instrument
# robinhood_ets.fundamentals
# robinhood_ets.quote()
# robinhood_ets.historicals()
