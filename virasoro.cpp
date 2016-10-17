#include <cstdlib>	// atoi
#include <cmath>
#include <chrono>
#include <iostream>
#include <quadmath.h>
#include "virasoro.h"
typedef std::chrono::high_resolution_clock Clock;

int main(int argc, char** argv){
	if(argc < 6 || !(std::atof(argv[1]) > 0.0) || !(std::atof(argv[2]) > 0) || !(std::atof(argv[3]) > 0) || !(std::atof(argv[4]) > 0.0) || std::atoi(argv[5]) < 1){
		printf("Error: Central charge c, two dimensions hl and hh, exchange dimension hp, and maximum order N in q^n required as arguments.\n");
		return EXIT_FAILURE;
	}
	auto timeStart = Clock::now();
	__float128 c = std::atof(argv[1]);
	if(c > 1.0 && c < 25.0){
		printf("Error: Currently not able to accommodate central charge between 1 and 25 due to intermediate complex numbers. Please try again later.\n");
		return EXIT_FAILURE;
	}
	__float128 hl = std::atof(argv[2]);
	__float128 hh = std::atof(argv[3]);
	__float128 hp = std::atof(argv[4]);
	if(std::atoi(argv[5]) > 65535){
		std::cout << "Error: this version of the program can not accommodate orders higher than 65,535. To remove this restriction, delete all instances of \"short\" and the statement which produces this message." << std::endl;
		return EXIT_FAILURE;
	}
	unsigned short int maxOrder = std::atoi(argv[5]);
	
	int mnLocation[maxOrder]; 	/* location in mn vector at which i+1 = m*n starts */
	int mnMultiplicity[maxOrder] = {0};	/* number of mn combinations giving i+1 */
	int numberOfMN = EnumerateMN(mnLocation, mnMultiplicity, maxOrder);
	unsigned short int mTable[numberOfMN] = {0};
	unsigned short int nTable[numberOfMN] = {0};
	int mnLookup[maxOrder*maxOrder];
	FillMNTable(mnLookup, mTable, nTable, numberOfMN, mnLocation, mnMultiplicity, maxOrder);
	
	__float128 bsq = CToB(c);
	__float128 invBsq = 1/bsq;
	__float128 hpmn[numberOfMN];
	FillHpmn(hpmn, mTable, nTable, numberOfMN, bsq, invBsq);
	__float128 llsq = hl - (c-1.0)/24.0;
	__float128 lhsq = hh - (c-1.0)/24.0;
	
	__float128 prodLkl[numberOfMN];
	auto time1 = Clock::now();
	FillProdLkl(prodLkl, bsq, invBsq, mTable, nTable, numberOfMN);
	auto time2 = Clock::now();
	std::cout << "ProdLkl filled. This took " << std::chrono::duration_cast<std::chrono::microseconds>(time2 - time1).count() << " us." << std::endl;
	
	// combine prodLKL into Rmn
	__float128 Rmn[numberOfMN] = {0};
	time1 = Clock::now();
	FillRmn(Rmn, prodLkl, bsq, invBsq, llsq, lhsq, numberOfMN, mnLookup, maxOrder);
	time2 = Clock::now();
	std::cout << "Rmn filled. This took " << std::chrono::duration_cast<std::chrono::microseconds>(time2 - time1).count() << " us." << std::endl;
	
	// combine Rmn and hpmn into computation of H
	__float128* Hmn[numberOfMN];
	for(int mn = 2; mn <= maxOrder; mn+=2){
		for(int i = 1; i <= mnMultiplicity[mn-1]; ++i){
			//std::cout << "Still alive; trying to create Hmn[" << mnLocation[mn-1]+i-1 << "] of " << numberOfMN-1 << ", which has mn=" << mn << " and needs to go up to order " << maxOrder-mn << "." << std::endl;
			Hmn[mnLocation[mn-1]+i-1] = new __float128[maxOrder-mn+1]{0};
			Hmn[mnLocation[mn-1]+i-1][0] = 1;
			//std::cout << "Just set H[" << mnLocation[mn]+i-1 << "][0] = 1." << std::endl;
		}
	}
	time1 = Clock::now();
	FillHmn(Hmn, Rmn, hpmn, mnLocation, mnMultiplicity, maxOrder);
	time2 = Clock::now();
	std::cout << "Hmn filled. This took " << std::chrono::duration_cast<std::chrono::microseconds>(time2 - time1).count() << " us." << std::endl;
	
	// corral H by q order and display coefficients
	__float128 H[maxOrder+1] = {1};
	FillH(H, Hmn, Rmn, hpmn, hp, mnLocation, mnMultiplicity, maxOrder);
	auto timeEnd = Clock::now();
	int elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(timeEnd - timeStart).count();
	std::string unit = "ms";
	if(elapsed > 1000){
		elapsed = std::chrono::duration_cast<std::chrono::seconds>(timeEnd - timeStart).count();
		unit = "s";
		if(elapsed > 60){
			elapsed = std::chrono::duration_cast<std::chrono::minutes>(timeEnd - timeStart).count();
			unit = "m";
		}
	}
	DisplayH(H, c, hl, hh, hp, maxOrder, elapsed, unit);
	
	return EXIT_SUCCESS;
}

int EnumerateMN (int* mnLocation, int* mnMultiplicity, const unsigned short int maxOrder){
	int numberOfMN = 0;
	for(int m=1; m <= maxOrder; ++m){
		for(int n=1; m*n <= maxOrder; ++n){
			++mnMultiplicity[m*n-1];
			++numberOfMN;
		}
	}
	mnLocation[0] = 0;
	for(int i = 2; i <= maxOrder; ++i){
		mnLocation[i-1] = mnLocation[i-2] + mnMultiplicity[i-2];
	}
	return numberOfMN;
}

// currently not able to deal with imaginary bsq from 1 < c < 25.
__float128 CToB (const __float128 c){
	__float128 bsq;
	if(c >= 1.0 && c <= 25.0){
		bsq = (c - 13.0)/12.0;
	} else {
		bsq = c - 13.0 - sqrt(c*c - 26.0*c + 25.0);
		bsq /= 12.0;
	}
	return bsq;
}

void FillMNTable (int *mnLookup, unsigned short int *mTable, unsigned short int *nTable, const int numberOfMN, const int *mnLocation, const int* mnMultiplicity, const unsigned short int maxOrder){
	int pos;
	for(int m = 1; m <= maxOrder; ++m){
		for(int n = 1; m*n <= maxOrder; ++n){
			for(pos = mnLocation[m*n-1]; pos <= mnLocation[m*n-1]+mnMultiplicity[m*n-1]-1; ++pos){
				if(mTable[pos]==0){
					mTable[pos] = m;
					nTable[pos] = n;
					mnLookup[(m-1)*maxOrder + n-1] = pos;
					break;
				}
			}
		}
	}
}

void FillHpmn (__float128 *hpmn, const unsigned short int *mTable, const unsigned short int *nTable, const int numberOfMN, const __float128 bsq, const __float128 invBsq){
	for(int pos = 1; pos <= numberOfMN; ++pos){
		hpmn[pos-1] = 0.25*(1.0-nTable[pos-1]*nTable[pos-1])*bsq + 0.25*(1.0-mTable[pos-1]*mTable[pos-1])*invBsq + 0.5 - 0.5*mTable[pos-1]*nTable[pos-1];
	}
	return;
}

void FillProdLkl(__float128 *prodLkl, const __float128 bsq, const __float128 invBsq, const unsigned short int *mTable, const unsigned short int *nTable, const int numberOfMN){
	for(int pos = 1; pos <= numberOfMN; ++pos){
		prodLkl[pos-1] = FindProdLkl(bsq, invBsq, mTable[pos-1], nTable[pos-1]);
	}
}

__float128 FindProdLkl(const __float128 bsq, const __float128 invBsq, const int m, const int n){
	__float128 prod = 1.0;
	for(int l = 1; l <= n-1; ++l){ 		// pairs of Lml*Lm(-l)
		prod *= +m*m*invBsq - l*l*bsq;
	}
	for(int k = 1; k <= m-1; ++k){ 		// pairs of Lkn*L(-k)n
		prod *= -k*k*invBsq + n*n*bsq;
	}
	for(int k = 1; k < m; ++k){ 		// pairs of Lk0*L(-k)0
		prod *= -k*k*invBsq;
	}	
	for(int l = 1; l < n; ++l){ 		// pairs of L0l*L0(-l)
		prod *= -l*l*bsq;
	}
	prod *= n;							// loose Lm0 and L0n
	prod *= -m;
	for(int k = 1; k <= m-1; ++k){		
		for(int l = 1; l <= n-1; ++l){
			prod *= -k*k*invBsq - 2*k*l - l*l*bsq;	// paired Lpq*L(-p)(-q)
			prod *= -k*k*invBsq + 2*k*l - l*l*bsq;	// paired L(-p)q*Lp(-q)
		}
	}
	return 1/prod;
}

void FillRmn(__float128 *Rmn, const __float128 *prodLkl, const __float128 bsq, const __float128 invBsq, const __float128 llsq, const __float128 lhsq, const int numberOfMN, const int* mnLookup, const unsigned short int maxOrder){
	__float128 Lsq;
	Rmn[0] = 0;
	Rmn[1] = (0.0625*bsq*bsq + llsq*bsq)*(0.0625*bsq*bsq + lhsq*bsq);
	Rmn[2] = (0.0625*invBsq*invBsq + llsq*invBsq)*(0.0625*invBsq*invBsq + lhsq*invBsq);
	Rmn[6] = (0.0625*(6.0 + invBsq*invBsq + 4.0*invBsq + 4.0*bsq + bsq*bsq) + llsq*(2.0 + invBsq + bsq))*(0.0625*(6.0 + invBsq*invBsq + 4.0*invBsq + 4.0*bsq + bsq*bsq) + lhsq*(2.0 + invBsq + bsq));
	Rmn[6] *= (0.0625*(6.0 + invBsq*invBsq - 4.0*invBsq - 4.0*bsq + bsq*bsq) + llsq*(-2.0 + invBsq + bsq))*(0.0625*(6.0 + invBsq*invBsq - 4.0*invBsq - 4.0*bsq + bsq*bsq) + lhsq*(-2.0 + invBsq + bsq));
	
	for(int m = 1; m <= 2; ++m){
		for(int n = 3+(m%2); m*n <= maxOrder; ++n){
			Rmn[mnLookup[(m-1)*maxOrder + n-1]] = Rmn[mnLookup[(m-1)*maxOrder + n-3]];
			for(int p = -m+1; p <= m-1; p+=2){
				Lsq = (-1.0 + 2.0*n - n*n)*bsq + 2.0*p*(1-n) - p*p*invBsq;
				Rmn[mnLookup[(m-1)*maxOrder + n-1]] *= (0.0625*Lsq*Lsq - llsq*Lsq)*(0.0625*Lsq*Lsq - lhsq*Lsq);
			}
		}
	}
	
	for(int m = 3; m <= maxOrder-(maxOrder%2); m+=2){
		for(int n = 2; m*n <= maxOrder; n+=2){
			Rmn[mnLookup[(m-1)*maxOrder + n-1]] = Rmn[mnLookup[(m-3)*maxOrder + n-1]];
			for(int q = -n+1; q <= n-1; q+=2){
				Lsq = (-1.0 + 2.0*m - m*m)*invBsq + 2.0*q*(1-m) - q*q*bsq;
				Rmn[mnLookup[(m-1)*maxOrder + n-1]] *= (0.0625*Lsq*Lsq - llsq*Lsq)*(0.0625*Lsq*Lsq - lhsq*Lsq);
			}
		}
		for(int n = 1; m*n+n <= maxOrder; ++n){
			Rmn[mnLookup[m*maxOrder + n-1]] = Rmn[mnLookup[(m-2)*maxOrder + n-1]];
			for(int q = -n+1; q <= n-1; q+=2){
				Lsq = -m*m*invBsq - 2.0*q*m - q*q*bsq;
				Rmn[mnLookup[m*maxOrder + n-1]] *= (0.0625*Lsq*Lsq - llsq*Lsq)*(0.0625*Lsq*Lsq - lhsq*Lsq);
			}
		}
	}

	for(int pos = 1; pos <= numberOfMN; ++pos){
		Rmn[pos-1] *= -0.5*prodLkl[pos-1];
	}
	
	return;
}

void FillHmn(__float128** Hmn, const __float128* Rmn, const __float128* hpmn, const int* mnLocation, const int* mnMultiplicity, const unsigned short int maxOrder){
	for(int order = 2; order <= maxOrder; order+=2){
		for(int mn = 2; mn <= maxOrder-order; mn+=2){
			for(int pos = mnLocation[mn-1] + 1; pos <= mnLocation[mn-1] + mnMultiplicity[mn-1]; ++pos){
				Hmn[pos-1][order] = HmnTerm(Hmn, Rmn, hpmn, hpmn[pos-1]+mn, mnLocation, mnMultiplicity, order);
			}
		}
	}
}

void FillH(__float128* H, const __float128* const* Hmn, const __float128* Rmn, const __float128* hpmn, const __float128 hp, const int* mnLocation, const int* mnMultiplicity, const unsigned short int maxOrder){
	for(int order = 2; order <= maxOrder; order+=2){
		H[order] = HmnTerm(Hmn, Rmn, hpmn, hp, mnLocation, mnMultiplicity, order);
	}
	return;
}

void DisplayH(const __float128* H, const __float128 c, const __float128 hl, const __float128 hh, const __float128 hp, const unsigned short int maxOrder, const int time, const std::string unit){
	std::cout << "Given the parameters" << std::endl;
	std::cout << "c = " << (long double)c << ", h_L = " << (long double)hl << ", h_H = " << (long double)hh << ", h_p = " << (long double)hp << std::endl;
	std::cout << "the Virasoro block coefficients are as follows:" << std::endl;
	for(int order = 0; order <= maxOrder; order+=2){
		std::cout << "q^" << order << ": " << (long double)H[order] << std::endl;
	}
	std::cout << "This computation took " << time << " " << unit << "." << std::endl;
}
