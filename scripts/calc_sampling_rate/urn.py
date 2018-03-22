
count=0

for i in xrange(1,n):
   if  i % int(n/100)  == 0:
        count+=1
	print ("%d/100"%count)
   X = ( (N-(i-1)) - C )
   Y = (N - (i-1))
   if i == 1:
     prod = (X / Y)
     print(i,prod)
   if i != 1:
     prod = prod * (X/Y)
     print("%.2f"%prod)

result = 1 - prod
print("N=%d,C=%d, n=%d, r=%.8f"%(N,C,n, n/N) )
print("The probability that at least one sector found (1-p) is: %.20f"%result)
print("The probability that not found (p) is: %.8f"%prod)
print("Sampling rate is: %.20f"%(n/N))


