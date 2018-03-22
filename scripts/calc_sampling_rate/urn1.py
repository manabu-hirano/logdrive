## N=2147483648.0 # sectors (100TiB/512)
## C=2086.0    #sectors (1MiB/512)
## n=5000000
count=0
DEBUG=1

N=2256800384.0      #  1TB
#N=22568003840.0     # 10TB
#N=225680038400.0    #100TB
#N=2256800384000.0    #  1PB
#N=22568003840000.0 # 10PB
#C=2.0       #  1 KiB
#C=20.0       # 10 KiB
#C=200.0      # 100 KiB
#C=2048.0    # 1 MiB
#C=20480.0    # 10 MiB
C=204800.0    # 100 MiB
#C=2097152.0  # 1 GiB


n=int(N/C*4.7) #99%
##n=int(N/C*2.4) #95%


for i in xrange(1,n):
   if DEBUG and i % int(n/5)  == 0:
        count+=1
	print ("%d/5"%count)
   X = ( (N-(i-1)) - C )
   Y = (N - (i-1))
   if i == 1:
     prod = (X / Y)
#     print(i,prod)
   if i != 1:
     prod = prod * (X/Y)
#     print("%.2f"%prod)

result = 1 - prod
print("N=%d,C=%d, n=%d, r=%.8f"%(N,C,n, n/N) )
print("The probability that at least one sector found (1-p) is: %.5f"%result)
print("The probability that not found (p) is: %.5f"%prod)

