#!/bin/bash
clean_failed_task () {
    echo "clean failed jobs"
    task_list=$(rally task list --uuids-only --status failed)
    rally task delete --force --uuid $task_list
}

clean_finished_task () {
    echo "clean finished tasks"
    task_list=$(rally task list --uuids-only --status finished)
    rally task delete --force --uuid $task_list
}

echo "Clean task in status:"
select yn in "Failed" "Finished" "Exit"; do
    case $yn in
        Failed ) clean_failed_task;;
        Finished ) clean_finished_task;;
        Exit ) exit;;
    esac
done 
