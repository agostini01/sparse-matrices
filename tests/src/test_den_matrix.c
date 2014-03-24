/**
 * Tomas Nesrovnal, nesro@nesro.cz, Copyright 2014
 * https://github.com/nesro/sparse-matrices
 */

#include <stdio.h>
#include <stdlib.h>

#include "../../src/virtual_matrix.h"
#include "../../src/den_matrix.h"

#include "../../cassertion/cassertion.h"
#include "test_utils.h"

static void run() {
	vm_t *a = NULL;
	vm_t *b = NULL;
	vm_t *c_def = NULL;
	vm_t *c_rec = NULL;
	//vm_t *c_str = NULL;

	const test_matrix_t *tm;
	const test_matrices_pair_t *tp;

	while ((tm = foreach_matrix(tm_small)) != NULL) {
		printf("%s\n", tm->path);
	}

	while ((tp = foreach_pair(tm_pairs)) != NULL) {
		printf("%s - %s\n", tp->a.path, tp->b.path);

		vm_load_mm(&a, DEN, tp->a.path);
		vm_load_mm(&b, DEN, tp->b.path);

		a->f.mul(a, b, &c_def, NAIVE);

		CASSERTION_TIME();
		a->f.mul(a, b, &c_rec, RECURSIVE);
		CASSERTION(c_def->f.distance(c_def, c_rec) == 0, "a=%s,b=%s, recursive",
				tp->a.path, tp->b.path);

		//a->f.mul(a, b, &c_str, STRASSEN);

		a->f.free(a);
		b->f.free(b);
		c_def->f.free(c_def);
		c_rec->f.free(c_rec);
		//c_str->f.free(c_str);
	}

//	vm_load_mm(&a, DEN, "./matrices/2x2_4nz_01.mtx");
//	vm_load_mm(&b, DEN, "./matrices/2x2_4nz_02.mtx");
//
//	a->f.mul(a, b, &c1, NAIVE);
//	a->f.mul(a, b, &c2, RECURSIVE);
//
//	printf("---- naive:\n");
//	c1->f.print(c1);
//	printf("---- recursive:\n");
//	c2->f.print(c2);
//
//	a->f.free(a);
//	b->f.free(b);
//	c1->f.free(c1);
//	c2->f.free(c2);
}

int main(int argc, char *argv[]) {

	CASSERTION_INIT(argc, argv);

	run();

	CASSERTION_RESULTS();

	return EXIT_SUCCESS;
}
