options gen2
options stack = 262144
require ../common/stencil_app.das
[export]
def main(smoke : bool) : int {return run_stencil(smoke)}
