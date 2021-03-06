package org.openforis.sepal.component.task.adapter

import org.openforis.sepal.component.task.api.WorkerSession
import org.openforis.sepal.component.task.api.WorkerSessionManager
import org.openforis.sepal.component.workersession.WorkerSessionComponent
import org.openforis.sepal.component.workersession.command.CloseSession
import org.openforis.sepal.component.workersession.command.Heartbeat
import org.openforis.sepal.component.workersession.command.RequestSession
import org.openforis.sepal.component.workersession.event.WorkerSessionClosed
import org.openforis.sepal.component.workersession.event.WorkerSessionActivated
import org.openforis.sepal.component.workersession.query.FindPendingOrActiveSession
import org.openforis.sepal.component.workersession.query.FindSessionById
import org.openforis.sepal.workertype.WorkerTypes

class SessionComponentAdapter implements WorkerSessionManager {
    private final WorkerSessionComponent sessionComponent

    SessionComponentAdapter(WorkerSessionComponent sessionComponent) {
        this.sessionComponent = sessionComponent
    }

    WorkerSession requestSession(String username, String instanceType) {
        def session = sessionComponent.submit(new RequestSession(
                username: username,
                workerType: WorkerTypes.TASK_EXECUTOR,
                instanceType: instanceType))
        return toTaskSession(session)
    }

    WorkerSession findPendingOrActiveSession(String username, String instanceType) {
        def session = sessionComponent.submit(new FindPendingOrActiveSession(
                username: username,
                workerType: WorkerTypes.TASK_EXECUTOR,
                instanceType: instanceType
        ))
        return toTaskSession(session)
    }

    WorkerSession findSessionById(String sessionId) {
        def session = sessionComponent.submit(new FindSessionById(sessionId))
        return toTaskSession(session)
    }

    void closeSession(String sessionId) {
        sessionComponent.submit(new CloseSession(sessionId: sessionId))
    }

    void heartbeat(String sessionId) {
        sessionComponent.submit(new Heartbeat(sessionId: sessionId))
    }

    String getDefaultInstanceType() {
        return sessionComponent.defaultInstanceType.id
    }

    SessionComponentAdapter onSessionActivated(Closure listener) {
        sessionComponent.on(WorkerSessionActivated) {
            listener(toTaskSession(it.session))
        }
        return this
    }

    SessionComponentAdapter onSessionClosed(Closure listener) {
        sessionComponent.on(WorkerSessionClosed) {
            listener(it.sessionId)
        }
        return this
    }

    private WorkerSession toTaskSession(org.openforis.sepal.component.workersession.api.WorkerSession session) {
        if (!session)
            return null
        return new WorkerSession(
                id: session.id,
                instanceType: session.instanceType,
                username: session.username,
                host: session.instance.host,
                state: session.state.name() as WorkerSession.State)
    }
}
