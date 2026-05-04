const core = require('@actions/core');
const github = require('@actions/github');

try{
    execute(`git diff --name-only HEAD~1`, stdout => {
    const files = getList(stdout);
    exportVariable('CHANGED_FILES', files);
  });
} catch (error) {
  core.setFailed(error.message);  
}