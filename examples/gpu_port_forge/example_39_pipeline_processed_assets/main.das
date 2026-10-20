options gen2
options stack = 262144
require ../common/pipeline_app.das
[export]
def main(smoke : bool) : int {return run_pipeline_comparison(smoke)}
