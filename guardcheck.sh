#!/bin/sh

export errors=0
export recursive=false
export root_path="."
export verbose=false

usage() {
	echo "Usage: $0 [-r] [-v] [-h] [-d path] file"
	echo "  -d: change the source root directory"
	echo "  -r: perform operation recursively"
	echo "  -v: enable verbose mode"
	echo "  -h: print this help message"
	exit 1
}

check_file() {
	file="$1"
	relative_path="${file#"$root_path"/}"
	guard=$(echo "${relative_path}" | tr '/.' '__' | tr '[:lower:]' '[:upper:]')__

	if ! grep -Eq "^#ifndef ${guard}$|^#define ${guard}$" "${file}"; then
		echo "Include guards missing or incorrect in $file. Should be '$guard'"
		errors=$((errors + 1))
		return 1
	else
		[ "$verbose" = true ] && echo "Found '$guard' in '$file'"
		return 0
	fi
}
while getopts "d:rvh" option; do
	case "$option" in
	d) root_path="$OPTARG" ;;
	r) recursive=true ;;
	v) verbose=true ;;
	h | *) usage ;;
	esac
done

shift $((OPTIND - 1))

[ -z "$*" ] && echo "Error: No input file(s) provided." && usage

root_path="$(realpath "$root_path")"
input_file="$(realpath "$1")"

for input_file in "$@"; do
	input_file="$(realpath "$input_file")"
	if [ -d "$input_file" ]; then
		[ "$recursive" = false ] && echo "Error: -r not specified; omitting directory '$input_file'" && continue
		find "$input_file" \( -name '*.h' -or -name '*.hpp' -or -name '*.hh' \) -print | while IFS= read -r line; do
			check_file "$line"
		done

	else
		[ ! -f "$input_file" ] && echo "Error: Input file does not exist: $input_file." && continue
		extension="${input_file##*.}"
		[ "$extension" != "hpp" ] && [ "$extension" != "h" ] && [ "$extension" != "hh" ] && continue
		check_file "$input_file"
	fi
done

if [ "$errors" -gt 0 ]; then
	echo "Encountered $errors errors."
	exit 1
fi

exit 0
