#define _POSIX_C_SOURCE 200809L
#include <err.h>
#include <fnmatch.h>
#include <limits.h>
#include <magic.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>
#include <unistd.h>

static char delim = '\n';
static bool invert = false;
static bool aflag = false;
static int verbose = 0;

bool test(magic_t cookie, char *glob, char *file) {
	bool matched;
	const char *file_mime;

	if (!(file_mime = magic_file(cookie, file)))
		errx(EX_UNAVAILABLE, "%s", magic_error(cookie));

	if (verbose >= 1) warnx("testing `%s' (`%s') against `%s'", file, file_mime, glob);

	/* Glob the type against the file's type... */
	matched = fnmatch(glob, file_mime, FNM_PATHNAME) != FNM_NOMATCH;

	return (matched ? !invert : invert);
}

int main(int argc, char *argv[]) {
	verbose = 0;

	int opt;
	while ((opt = getopt(argc, argv, "!0av")) != -1) {
		switch (opt) {
		case '!': invert = true; break;
		case '0': delim = '\0'; break;
		case 'a': aflag = true; break;
		case 'v': verbose++; break;
		default:
			fprintf(stderr,
			        "usage: ... | %s [-!0v] MIME...\n"
			        "       %s [-!0v] -a MIME... -- FILE...\n",
			        argv[0], argv[0]);
			exit(EX_USAGE);
		}
	}

	/* Ask libmagic(3) to only give us the mime/type, and treat OS errors as real errors. */
	magic_t cookie = magic_open(MAGIC_MIME_TYPE | MAGIC_ERROR);
	if (!(magic_load(cookie, NULL) == 0)) errx(EX_UNAVAILABLE, "%s", magic_error(cookie));

	bool found = false;
	if (aflag) {
		/* Find where -- is in argv; that's the file list */
		int fileind = 0;

		for (int i = 1; i < argc; i++) {
			if (strcmp(argv[i], "--") == 0) {
				fileind = i + 1;
				break;
			}
		}

		for (int fi = fileind; fi < argc; fi++) {
			for (int mi = optind; mi < fileind; mi++) {
				if (test(cookie, argv[mi], argv[fi])) {
					printf("%s%c", argv[fi], delim);
					found = true;
					break;
				}
			}
		}
	} else {
		char *file = NULL;
		size_t size = 0;

		int read;
		/* Receive list of files on stdin. */
		while ((read = getdelim(&file, &size, delim, stdin)) != -1) {
			if (file[read - 1] == delim) file[read - 1] = 0;

			for (int mi = optind; mi < argc; mi++) {
				if (test(cookie, argv[mi], file)) {
					printf("%s%c", file, delim);
					found = true;
					break;
				}
			}
		}
	}

	return !found;
}
