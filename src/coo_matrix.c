/**
 * Tomas Nesrovnal, nesro@nesro.cz, Copyright 2013-2014
 * https://github.com/nesro/sparse-matrices
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "utils.h"
#include "mmio.h"
#include "mm_load.h"
#include "coo_matrix.h"

static vm_vmt_t coo_vmt = { /**/
(reset_t) NULL, /**/
(free_t) coo_free, /**/
(mm_load_t) NULL,/**/
(mm_save_t) NULL, /**/
(print_t) NULL, /**/
(compare_t) NULL, /**/
(distance_t) NULL, /**/
(convert_t) coo_convert, /**/
(mul_t) coo_mul, /**/
};

void coo_vm_init(coo_matrix_t **coo, va_list va) {

	int va_flag = 0;
	int width;
	int height;
	int nnz;

	nnz = va_get_int(va, 1, &va_flag);
	height = va_get_int(va, -1, &va_flag);
	width = va_get_int(va, -1, &va_flag);

	coo_init(coo, width, height, nnz);
}

void coo_init(coo_matrix_t **coo, int width, int height, int nnz) {

	/* XXX: */
	assert(width == height);

	*coo = calloc(1, sizeof(coo_matrix_t));
	(*coo)->_.object_size += sizeof(coo_matrix_t);
	assert(*coo != NULL);

	(*coo)->_.type = COO;
	(*coo)->_.f = coo_vmt;
	(*coo)->_.w = width;
	(*coo)->_.h = height;
	(*coo)->_.nnz = nnz;

	(*coo)->v = malloc(nnz * sizeof(datatype_t));
	(*coo)->_.object_size += nnz * sizeof(datatype_t);
	assert((*coo)->v != NULL);

	/*
	 * Because col and row are the same type, we'll call only one malloc.
	 */
	(*coo)->c = malloc(2 * nnz * sizeof(int));
	(*coo)->_.object_size += 2 * nnz * sizeof(int);
	assert((*coo)->c != NULL);
	(*coo)->r = &((*coo)->c[nnz]);

}

void coo_free(coo_matrix_t *coo) {
	free(coo->v);
	free(coo->c);
	free(coo);
}

vm_t *coo_convert(coo_matrix_t *coo, vm_type_t type) {

	printf("coo_convert\n");

	vm_t *vm = NULL;
	int i;

	switch (type) {
	case COO:
		vm_create(&vm, COO, coo->_.nnz, coo->_.w, coo->_.h);

		/*
		 * After the array of column indices are row indices. See
		 * initialization at the coo_init function.
		 */
		memcpy(((coo_matrix_t*) vm)->c, coo->c, 2 * coo->_.nnz * sizeof(int));
		memcpy(((coo_matrix_t*) vm)->v, coo->v,
				coo->_.nnz * sizeof(datatype_t));

		break;
	case DEN:
		vm_create(&vm, DEN, 1, coo->_.w, coo->_.h);

		for (i = 0; i < coo->_.nnz; i++)
			((den_matrix_t *) vm)->v[coo->r[i]][coo->c[i]] += coo->v[i];

		break;
	default:
		fdie("Unknown format to convert: %d\n", type);
		break;
	}

	return vm;
}

/******************************************************************************/

/*
 * When we transpose COO matrix, the arrays are not anymore sorted by y coords
 * and then by x coords.
 */
static void coo_sort(coo_matrix_t *coo) {

	int i;
	int j;

	int swap_r;
	int swap_c;
	datatype_t swap_v;

	/* bubble sort */
	for (i = 0; i < (coo->_.nnz - 1); i++) {
		for (j = 0; j < coo->_.nnz - i - 1; j++) {
			if (coo->r[j] > coo->r[j + 1]) {
				swap_r = coo->r[j];
				swap_c = coo->c[j];
				swap_v = coo->v[j];

				coo->r[j] = coo->r[j + 1];
				coo->c[j] = coo->c[j + 1];
				coo->v[j] = coo->v[j + 1];

				coo->r[j + 1] = swap_r;
				coo->c[j + 1] = swap_c;
				coo->v[j + 1] = swap_v;
			}
		}
	}
}

/*
 * This is implemented for no reason.
 */
void coo_transpose(coo_matrix_t *coo) {

	int i;
	int swap;

	for (i = 0; i < coo->_.nnz; i++) {
		swap = coo->r[i];
		coo->r[i] = coo->c[i];
		coo->c[i] = swap;
	}

	coo_sort(coo);
}

/******************************************************************************/

static double mul_coo_coo(const coo_matrix_t *a, const coo_matrix_t *b,
		den_matrix_t *c) {

	double start_time;

	start_time = omp_get_wtime();

	printf("coo coo mul is not implemented yet\n");

	return omp_get_wtime() - start_time;
}

/*
 * [BI-BAP: COO matrix X vector]
 */
static double mul_coo_vec(const coo_matrix_t *a, const vec_t *b, vec_t *c) {

	double start_time;
	int n;

	start_time = omp_get_wtime();

	for (n = 0; n < a->_.nnz; n++)
		c->v[a->r[n]] += a->v[n] * b->v[a->c[n]];

	return omp_get_wtime() - start_time;
}

/*
 * Matrix-Matrix multiplication in COO format.
 */
double coo_mul(const coo_matrix_t *a, const vm_t *b, vm_t **c,
		char flag /* unused */) {

	switch (b->type) {
	case VEC:
		vec_init((vec_t **) c, a->_.w);
		return mul_coo_vec(a, (vec_t *) b, (vec_t *) *c);
	case COO:
		den_matrix_init((den_matrix_t **) c, a->_.w, b->h, 1);
		return mul_coo_coo(a, (coo_matrix_t *) b, (den_matrix_t *) *c);
	default:
		fprintf(stderr, "Unknown matrix type: %d\n", b->type);
		exit(1);
		return 0.;
	}
}

/******************************************************************************/

double coo_from_mm(coo_matrix_t **coo, const char *filename,
		va_list va /* unused */) {

	int i;
	mm_file_t *mm_file;

	/* XXX: FIXME: ssh! - for test purposes of course (8 */
	mm_file = mm_load(filename, 1);

	coo_init(coo, mm_file->width, mm_file->height, mm_file->nnz); /* N=width, M=height */

	for (i = 0; i < mm_file->nnz; i++) {
		(*coo)->r[i] = mm_file->data[i].row;
		(*coo)->c[i] = mm_file->data[i].col;
		(*coo)->v[i] = mm_file->data[i].value;
	}

	mm_free(mm_file);

	return 1.;
}
