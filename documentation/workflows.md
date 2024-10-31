# Github Workflows

## Optimizations

- Parallelize with multiple jobs
    ```yaml 
        jobs:
            build:
            name: 'name-of-job'
            runs-on: ubuntu-latest
            steps: 
                - name: first step
                  run: | 
                        echo "Hello World"  
        
            test:
            needs: [build]
            name: 'name-of-job'
            runs-on: ubuntu-latest
            steps: 
                - name: first step
                  run: | 
                        echo "Test World"  
    ```
   > **OBS**: Be aware that every job is billed per minute started. Running a workflow job for less then 6 seconds will still be billed for 1 minute.

