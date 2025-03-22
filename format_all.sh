# Format all the nim files on src directory using nph
# Usage: ./format_all.sh

set -e

FILES=$(find src -name "*.nim")
# Check if nph is installed
if ! command -v nph &> /dev/null
then
    echo "nph could not be found. Please install it first."
    exit
fi
# check if formatin is required
if nph --check $FILES ; then
    echo "No formatting required"
    exit
fi
# Format all files
echo "Formatting all nim files in src directory"
nph ${FILES}