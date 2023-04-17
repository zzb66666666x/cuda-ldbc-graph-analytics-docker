#include <cstdio>
#include <cstdlib>

#include "template.hu"

#define TILE_SZ_A 128
#define TILE_SZ_B 16
#define TILE_SZ_RATIO (TILE_SZ_A/TILE_SZ_B)

__global__ void mysgemm(int m, int n, int k, const float *A, const float *B, float* C) {

  /********************************************************************
  *
  * Compute C = A x B
  *   where A is a (m x k) matrix
  *   where B is a (k x n) matrix
  *   where C is a (m x n) matrix
  *
  * Use register and shared memory tiling and thread coarsening
  *
  * NOTE: A and C are column major, B is row major
  *
  ********************************************************************/

  // Macros for accessing flattened matrices
  #define A(row,col) A[(row) + (col)*m]
  #define B(row,col) B[(row)*n + (col)]
  #define C(row,col) C[(row) + (col)*m]

  // INSERT KERNEL CODE HERE
	__shared__ float MatBCache[TILE_SZ_RATIO][TILE_SZ_B];
  // thread local array for partial sums
  float pvalues[TILE_SZ_B];
  for (int i=0; i<TILE_SZ_B; i++){
    pvalues[i] = 0;
  }
	int ty = threadIdx.y;
	int Row = blockIdx.y * blockDim.y + ty;
	int Col_Start = blockIdx.x * TILE_SZ_B;
	int Col_End = Col_Start + TILE_SZ_B - 1;
	Col_End = (Col_End > n-1)? n-1 : Col_End;
  int numCols = Col_End - Col_Start + 1;
	int numIteration = (k - 1)/TILE_SZ_RATIO + 1;
	for (int q = 0; q < numIteration; q++){
		int cache_i = ty / TILE_SZ_B;
		int cache_j = ty % TILE_SZ_B;
		int MatB_Row_Idx = q*TILE_SZ_RATIO + cache_i;
		int MatB_Col_Idx = Col_Start + cache_j;
		if (MatB_Col_Idx < n && MatB_Row_Idx < k){
			MatBCache[cache_i][cache_j] = B(MatB_Row_Idx, MatB_Col_Idx);
		}else{
      MatBCache[cache_i][cache_j] = 0;
    }
		float MatATile_0 = (Row < m)? A(Row, q*TILE_SZ_RATIO): 0;
		__syncthreads();
		if (Row < m){
			for (int Col = Col_Start; Col <= Col_End; Col++){
				int Col_relative = Col - Col_Start;
				// float pvalue = MatATile_0 * MatBCache[0][Col_relative];
				// for (int s = 1; s < TILE_SZ_RATIO; s++){
				// 	pvalue += (MatBCache[s][Col_relative] * A(Row, q*TILE_SZ_RATIO + s));
				// }
        // pvalues[Col_relative] += pvalue;
        pvalues[Col_relative] += MatATile_0 * MatBCache[0][Col_relative];
				for (int s = 1; s < TILE_SZ_RATIO; s++){
					pvalues[Col_relative] += (MatBCache[s][Col_relative] * A(Row, q*TILE_SZ_RATIO + s));
				}
			}
		}
    __syncthreads();
	}
  if (Row < m){
      for (int i=0; i<numCols; i++){
        C(Row, Col_Start+i) = pvalues[i];
      }
  }
  // SSL Hint (9/6/21): try using just one register for the tile of A 
  // rather than several--in other words, load one value (per thread) 
  // from A and compute using that value rather than loading all values 
  // before doing the computation.  This approach seems to be slightly 
  // faster than the alternative.
}

void basicSgemm(char transa, char transb, int m, int n, int k, float alpha, const float *A, int lda, const float *B, int ldb, float beta, float *C, int ldc)
{
  if ((transa != 'N') && (transa != 'n')) {
		printf("unsupported value of 'transa'\n");
    return;
  }

  if ((transb != 'T') && (transb != 't')) {
		printf("unsupported value of 'transb'\n");
		return;
  }

  if ((alpha - 1.0f > 1e-10) || (alpha - 1.0f < -1e-10)) {
		printf("unsupported value of alpha\n");
		return;
  }

  if ((beta - 0.0f > 1e-10) || (beta - 0.0f < -1e-10)) {
		printf("unsupported value of beta\n");
		return;
  }

	// Initialize thread block and kernel grid dimensions ---------------------

	// Your code need only consider the m, n, k, A, B, and C parameters of
	// the function, which provide the matrix sizes (m, n, k) and data
	// (A, B, C).

	//INSERT CODE HERE
	dim3 dimGrid(ceil((float)n / TILE_SZ_B), ceil((float)m / TILE_SZ_A), 1);
	dim3 dimBlock(1, TILE_SZ_A, 1);
	// Invoke CUDA kernel -----------------------------------------------------
	mysgemm<<<dimGrid, dimBlock>>>(m, n, k, A, B, C);
	//INSERT CODE HERE

}

