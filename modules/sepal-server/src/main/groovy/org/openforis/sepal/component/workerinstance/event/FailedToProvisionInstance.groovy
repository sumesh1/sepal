package org.openforis.sepal.component.workerinstance.event

import groovy.transform.Immutable
import org.openforis.sepal.component.workerinstance.api.WorkerInstance
import org.openforis.sepal.event.Event

@Immutable
class FailedToProvisionInstance implements Event {
    WorkerInstance instance
    String error
}
