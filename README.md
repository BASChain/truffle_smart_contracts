# smart_contract
smart contracts base on ethereum

## deployment 
with remix compiler 0.5.1.2

## how to deploy contracts?

> deploy sequence
1.  BasToken
2.  BasExpiredOwnership,     label "mail"
3.  BasTradableOwnership,    label "domain"
4.  BasRootDomain
5.  BasSubDomian
6.  BasDomainConf
7.  BasAccountant
8.  BasMiner
9.  BasOANN
10. BasMarket
11. BasMail
12. BasMailManager

> link sequence

1. BasTradableOwnership :: addDataKeeper(BasRootDomain)
2. BasTradableOwnership :: addDataKeeper(BasSubDomain)
3. BasTradableOwnership :: addDataKeeper(BasMarket)
4. BasAccountant :: addDataKeeper(BasOANN)
5. BasAccountant :: addDataKeeper(BasMailManager)
6. BasMiner :: addDataKeeper(BasAccountant)
7. BasMail :: addDataKeeper(BasMailManager)
8. BasExpiredOwnership :: addDataKeeper(BasMail)