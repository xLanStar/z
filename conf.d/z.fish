if status is-interactive
    function __zoxide_cd
        if set -q __zoxide_loop
            builtin echo "zoxide: infinite loop detected"
            builtin echo "Avoid aliasing `cd` to `z` directly, use `zoxide init --cmd=cd fish` instead"
            return 1
        end
        __zoxide_loop=1 builtin cd $argv
    end


    function __zoxide_hook --on-variable PWD
        test -z "$fish_private_mode"
        and command zoxide add -- (builtin pwd -L)
    end


    function z
        set -l argc (builtin count $argv)
        if test $argc -eq 0
            __zoxide_cd $HOME
        else if test "$argv" = -
            __zoxide_cd -
        else if test $argc -eq 1 -a -d $argv[1]
            __zoxide_cd $argv[1]
        else if test $argc -eq 2 -a $argv[1] = --
            __zoxide_cd -- $argv[2]
        else
            set -l result (command zoxide query --exclude (builtin pwd -L) -- $argv)
            and __zoxide_cd $result
        end
    end

    function z_complete
        set -l tokens (builtin commandline --current-process --tokenize)
        set -l curr_tokens (builtin commandline --cut-at-cursor --current-process --tokenize)

        if test (builtin count $tokens) -le 2 -a (builtin count $curr_tokens) -eq 1
            # If there are < 2 arguments, use `cd` completions.
            complete --do-complete "'' "(builtin commandline --cut-at-cursor --current-token) | string match --regex -- '.*/$'
        else if test (builtin count $tokens) -eq (builtin count $curr_tokens)
            # If the last argument is empty, use interactive selection.
            set -l query $tokens[2..-1]
            set -l result (command zoxide query --exclude (builtin pwd -L) --interactive -- $query)
            and __zoxide_cd $result
            and builtin commandline --function cancel-commandline repaint
        end
    end
    complete --command z --no-files --arguments '(z_complete)'

    function zi
        set -l result (command zoxide query --interactive -- $argv)
        and __zoxide_cd $result
    end
end