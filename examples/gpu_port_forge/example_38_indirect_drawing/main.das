options gen2
options stack = 262144
require ../common/indirect_app.das
[export]
def main(smoke : bool) : int {return run_indirect(smoke)}
