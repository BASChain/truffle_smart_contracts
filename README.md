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
3. BasAccountant :: addDataKeeper(BasOANN)
4. BasAccountant :: addDataKeeper(BasMailManager)
5. BasMiner :: addDataKeeper(BasAccountant)
6. BasMail :: addDataKeeper(BasMailManager)
7. BasTradableOwnership :: addDataKeeper(BasMarket)
8. BasExpiredOwnership :: addDataKeeper(BasMail)