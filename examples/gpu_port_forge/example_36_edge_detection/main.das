options gen2
options stack = 262144
require ../common/edge_app.das
[export]
def main(smoke : bool) : int {return run_edges(smoke)}
