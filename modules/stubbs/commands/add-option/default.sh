#!/usr/bin/env bash
#
# NAME
#
#   add-option
#
# DESCRIPTION
#
#   add a command option
#

# Source common function library
source $RERUN_MODULES/stubbs/lib/functions.sh || { echo "failed laoding function library" ; exit 1 ; }

# Upper case the string and change dashes to underscores.
trops() { echo "$1" | tr '[:lower:]' '[:upper:]' | tr  '-' '_' ; }

# Used to generate an entry inside options.sh
add_optionparser() {
	local optName=$1
    local optVarname=$(trops $optName)
	local ARGUMENTS=$(rerun_optionArguments $RERUN_MODULES $MODULE $COMMAND $optName)
	local SHORT=$(rerun_optionShort $RERUN_MODULES $MODULE $COMMAND $optName)
	if [ -n "${SHORT}" ] 
	then
		argstring=$(printf ' -%s|--%s' "${SHORT}" "${optName}")
	else
		argstring=$(printf " --%s" "${optName}" )
    fi
	if [ "$ARGUMENTS" == "false" ]
	then
		printf " %s) %s=true ;;\n" "${argstring}" "$optVarname"
	else
    	printf " %s) rerun_option_check \$# ; %s=\$2 ; shift ;;\n" \
			"$argstring" "$optVarname"
	fi
}

add_commandUsage() {
    [ $# = 3 ] || { echo "usage add_commandUsage <moddir> <module> <command>" ; return 1 ; }
    local moddir=$1 module=$2 command=$3

    for opt in $(rerun_options $moddir $module $command); do
        [ -f $RERUN_MODULES/$MODULE/commands/${command}/${opt}.option ] || continue
        (
            local usage=
            source  $RERUN_MODULES/$MODULE/commands/${command}/${opt}.option
		    if [ -n "${SHORT}" ] 
		    then
			    argstring=$(printf ' -%s|--%s' "${SHORT}" "${NAME}")
		    else
			    argstring=$(printf " --%s" "${NAME}" )
		    fi		  
		    [ "true" == "${ARGUMENTS}" ] && {
			    argstring=$(printf "%s <%s>" "$argstring" "${DEFAULT}")
		    }
		    [ "true" != "${REQUIRED}" ] && {
			    usage=$(printf "[%s]" "${argstring}") 
		    } || {
			    usage=$(printf "%s" "${argstring}")
		    }
            printf "%s " "$usage"
        )
    done
}

# Init the handler
rerun_init 

# Get the options
while [ "$#" -gt 0 ]; do
    OPT="$1"
    case "$OPT" in
        # options without arguments
	# options with arguments
	-o|--option)
	    rerun_option_check "$#"
	    OPTION="$2"
	    shift
	    ;;
	--desc*)
	    rerun_option_check "$#"
	    DESC="$2"
	    shift
	    ;;
	-c|--command)
	    rerun_option_check "$#"
		# Parse if command is named "module:command"
	 	regex='([^:]+)(:)([^:]+)'
		if [[ $2 =~ $regex ]]
		then
			MODULE=${BASH_REMATCH[1]}
			COMMAND=${BASH_REMATCH[3]}
		else
	    	COMMAND="$2"		
	    fi
	    shift
	    ;;
	-m|--module)
	    rerun_option_check "$#"
	    MODULE="$2"
	    shift
	    ;;
	--req*)
	    rerun_option_check "$#"
	    REQ="$2"
	    shift
	    ;;
	--arg*)
	    rerun_option_check "$#"
	    ARGS="$2"
	    shift
	    ;;
	--long)
	    rerun_option_check "$#"
	    LONG="$2"
	    shift
	    ;;
	-range)
	    rerun_option_check "$#"
	    RANGE="$2"
	    shift
	    ;;			
	-d|--default)
	    rerun_option_check "$#"
	    DEFAULT="$2"
	    shift
	    ;;
        # unknown option
	-?)
	    rerun_option_error
	    ;;
	  # end of options, just arguments left
	*)
	    break
    esac
    shift
done

# Post process the options
[ -z "$OPTION" ] && {
    echo "Option: "
    read OPTION
}

[ -z "$DESC" ] && {
    echo "Description: "
    read DESC
}

[ -z "$MODULE" ] && {
    echo "Module: "
    select MODULE in $(rerun_modules $RERUN_MODULES);
    do
	echo "You picked module $MODULE ($REPLY)"
	break
    done
}

[ -z "$COMMAND" ] && {
    echo "Command: "
    select COMMAND in $(rerun_commands $RERUN_MODULES $MODULE);
    do
	echo "You picked command $COMMAND ($REPLY)"
	break
    done
}

[ -z "$REQ" ] && {
    echo "Required (true/false): "
    select REQ in true false;
    do
	break
    done
}


[ -z "$DEFAULT" ] && {
    echo "Default: "
    read DEFAULT
}

# Verify this command exists
#
[ -d $RERUN_MODULES/$MODULE/commands/$COMMAND ] || rerun_die "command does not exist: \""$MODULE:$COMMAND\"""

# Generate metadata for new option

(
    cat <<EOF
# generated by stubbs:add-option
# $(date)
NAME=$OPTION
DESCRIPTION="$DESC"
ARGUMENTS=${ARGS:-true}
REQUIRED=${REQ:-true}
SHORT=${OPTION:0:1}
LONG=${LONG:-$OPTION}
DEFAULT=$DEFAULT
RANGE=$RANGE

EOF
) > $RERUN_MODULES/$MODULE/commands/$COMMAND/$OPTION.option || rerun_die
echo "Wrote option metadata: $RERUN_MODULES/$MODULE/commands/$COMMAND/$OPTION.option"


# list the options that set a default
optionsWithDefaults=
for opt in $(rerun_options $RERUN_MODULES $MODULE $COMMAND); do
    default=$(rerun_optionDefault $RERUN_MODULES $MODULE $COMMAND $opt)
    args=$(rerun_optionArguments $RERUN_MODULES $MODULE $COMMAND $opt)
    [ -n "$default" -a "$args" == "true" ] && optionsWithDefaults="$optionsWithDefaults $opt"
done

# list the options that are required
optionsRequired=
for opt in $(rerun_options $RERUN_MODULES $MODULE $COMMAND); do
    required=$(rerun_optionRequired $RERUN_MODULES $MODULE $COMMAND $opt)
    args=$(rerun_optionArguments $RERUN_MODULES $MODULE $COMMAND $opt)
    [ "$required" == "true" -a "$args" = "true" ] && optionsRequired="$optionsRequired $opt"
done

# Generate option parser script.

(
cat <<EOF
# Generated by stubbs:add-option
# Created: $(date)
#
#/ usage: $MODULE:$COMMAND $(add_commandUsage $RERUN_MODULES $MODULE $COMMAND)

# print USAGE and exit
rerun_option_usage() {
    grep '^#/' <"\$RERUN_MODULES/$MODULE/$COMMAND/options.sh" | cut -c4-
    return 2
}

# check option has its argument
rerun_option_check() {
    [ "\$1" -lt 2 ] && rerun_option_usage
}

# options: [$(rerun_options $RERUN_MODULES $MODULE $COMMAND)]
while [ "\$#" -gt 0 ]; do
    OPT="\$1"
    case "\$OPT" in
$(for o in $(rerun_options $RERUN_MODULES $MODULE $COMMAND); do 
printf "      %s\n" "$(add_optionparser $o)"; 
done)
        # help option
        -?)
            rerun_option_usage
            ;;
        # end of options, just arguments left
        *)
          break
    esac
    shift
done

# If defaultable options variables are unset, set them to their DEFAULT
$(for opt in $(echo $optionsWithDefaults|sort); do
printf "[ -z \"$%s\" ] && %s=\"%s\"\n" $(trops $opt) $(trops $opt) $(rerun_optionDefault $RERUN_MODULES $MODULE $COMMAND $opt)
done)
# Check required options are set
$(for opt in $(echo $optionsRequired|sort); do
printf "[ -z \"$%s\" ] && { echo \"missing required option: --%s\" >&2 ; return 2 ; }\n" $(trops $opt) $opt
done)
#
return 0
EOF
) > $RERUN_MODULES/$MODULE/commands/$COMMAND/options.sh || rerun_die
echo "Wrote options script: $RERUN_MODULES/$MODULE/commands/$COMMAND/options.sh"

# Done


