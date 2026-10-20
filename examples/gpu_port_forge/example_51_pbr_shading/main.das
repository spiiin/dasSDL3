options gen2
options stack = 262144
require ../common/pbr_app.das
[export]
def main(smoke : bool) : int {return run_pbr(51,smoke)}
