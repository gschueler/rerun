# stubbs: Utility to create rerun modules

Use `stubbs` to define new *rerun* modules and commands.

## Commands

### add-module

Make a new module named "freddy":

    rerun -m stubbs -c add-module  -- -name freddy -description "A dancer in a red beret and matching suspenders"

### add-command

Add a command named "dance" to the freddy module:

    rerun -m stubbs -c add-command -- -name dance -description "tell freddy to dance" -module freddy

You will see output similar to:

    Created command handler: /Users/alexh/.rerun/modules/freddy/commands/dance/default.sh

### add-option

Define an option named "jumps":

    rerun -m stubbs -c add-option  -- -name jumps -description "jump #num times" -module freddy -command dance

You will see output similar to:

    Created option: /Users/alexh/.rerun/modules/freddy/commands/dance/jumps.option

Besides the `jumps.option` file, `add-option` will also create an
option parser script in `$RERUN_MODULES/$MODULE/commands/$COMMAND/options.sh`.

## Command implementation

Running `add-command` as shown above will generate a stub implementation
for the new command.
The stub implementation for the "dance" command is shown below:

    #!/bin/bash
    #
    # NAME
    #
    #   dance 
    #
    # DESCRIPTION
    #
    #   tell freddy to dance
     
    # Function to print error message and exit
    die() {
        echo "ERROR: $* " ; exit 1;
    }
     
    # Parse the command options     
    . $RERUN_MODULES/freddy/commands/dance/options.sh
     
    # Option values available in variables: JUMPS
     
    # ------------------------------
    # Your implementation goes here.
    # ------------------------------
     
    exit $?

The supplied name and description are shown in the top comment.
A "die" function is provided for convenience. 
Option parsing is handled via sourcing the `options.sh` script
generated by `add-option`.

Of course, your implementation goes in between the rows
of dashes.

    # ------------------------------
    echo "jumps ($JUMPS)"
    # ------------------------------
    
    exit $?

Always faithfully check and return use exit codes!

Try running the command

    rerun -m freddy -c dance -- -jumps 3
    jumps (3)

### Option defaults

If a command option is not set by the user, the option
can be set to a default value.

Use add-option's `-default <>` parameter to set the value. 
Here the "jumps" is set to a default value of "1":

    rerun -m stubbs -c add-option  -- \
      -name jumps -description "jump #num times" -module freddy -command dance \
      -default 1

Run the "dance" command again but this time without the "jumps" option:

    $ rerun -m freddy -c dance
    jumps (1)
    
To support this, the "dance" command's `options.sh` script is re-written.

