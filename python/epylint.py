#!/usr/bin/env python

import re
import sys

from subprocess import Popen, PIPE

ignore = ",".join ( [

] )

cmd = "pylint --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}' --rcfile='%s' --reports=n %s" % \
    ( sys.argv[1], sys.argv[2] )

p = Popen ( cmd, shell = True, bufsize = -1,
            stdin = PIPE, stdout = PIPE, stderr = PIPE, close_fds = True )
pylint_re = re.compile (
    '^([^:]+):(\d+):\s*\[([WECR])([^,]+),\s*([^\]]+)\]\s*(.*)$'
)
for line in p.stdout:
    line = line.strip()
    m = pylint_re.match ( line )
    if m:
        filename, linenum, errtype, errnum, context, description = m.groups()
        if errtype == "E":
            msg = "Error"
        else:
            msg = "Warning"
        # Here we are targetting the following flymake regexp:
        #
        #  ("\\(.*\\) at \\([^ \n]+\\) line \\([0-9]+\\)[,.\n]" 2 3 nil 1)
        #
        # where the number at the end indicate the index into the regexp
        # groups of ( file, line, column, error text )
        #
        # You can see what regexps flymake uses to parse its output by
        # running 'M-x describe-variable' on the variable
        # 'flymake-err-line-patterns'

        print "%s %s%s %s at %s line %s." % ( msg, errtype, errnum,
                                                  description, filename, linenum )
