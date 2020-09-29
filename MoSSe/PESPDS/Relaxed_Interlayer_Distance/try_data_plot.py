import matplotlib.pyplot as plt
import numpy as np




fh=open("energy.dat",'r')
z=[]

for i in fh:
	line=i
	word=line.split()
	energy=float(word[2])
	z.append(energy)
	
#print(z)
#print(z)

#print(min(z))
zz=min(z)
for j in range(len(z)):
	z[j]=z[j]-zz
	z[j]=z[j]*13.6056980659*1000
#print(z)

x_list = np.array([0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5])
y_list = np.array([0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5])
#x_list = np.array([0,1,2,3,4,5])
#y_list = np.array([0,1,2,3,4,5])
z_list = np.array(z)


N = int(len(z_list)**.5)
#print(N)
#print(x_list)
#print(y_list)
#print(z_list)
Z = z_list.reshape(N,N)
Z = Z.transpose()
#print(Z)
#plt.imshow(Z, extent=(np.amin(x_list), np.amax(x_list), np.amin(y_list), np.amax(y_list)), norm= LogNorm(), aspect = 'auto')
plt.contourf(x_list, y_list, Z, 44, cmap = 'jet')
#X, Y = np.meshgrid(x_list, y_list)
#plt.imshow(Z,origin='lower',interpolation='bilinear')
plt.colorbar()
plt.show()
#print(x_list)
#print(y_list)
#print(z_list)	
