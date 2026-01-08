package com.example.akka.sbr;

import akka.actor.typed.Behavior;
import akka.actor.typed.javadsl.AbstractBehavior;
import akka.actor.typed.javadsl.ActorContext;
import akka.actor.typed.javadsl.Behaviors;
import akka.actor.typed.javadsl.Receive;
import akka.cluster.ClusterEvent;
import akka.cluster.typed.Cluster;
import akka.cluster.typed.Subscribe;
import org.slf4j.Logger;

public class ClusterListener extends AbstractBehavior<ClusterEvent.ClusterDomainEvent> {

    private final Cluster cluster;
    private final Logger log;

    public static Behavior<ClusterEvent.ClusterDomainEvent> create() {
        return Behaviors.setup(ClusterListener::new);
    }

    private ClusterListener(ActorContext<ClusterEvent.ClusterDomainEvent> context) {
        super(context);
        this.log = context.getLog();
        this.cluster = Cluster.get(context.getSystem());

        // Subscribe to cluster events
        cluster.subscriptions().tell(Subscribe.create(context.getSelf(), ClusterEvent.ClusterDomainEvent.class));
    }

    @Override
    public Receive<ClusterEvent.ClusterDomainEvent> createReceive() {
        return newReceiveBuilder()
                .onMessage(ClusterEvent.MemberUp.class, event -> {
                    log.info("Member is Up: {}", event.member());
                    return Behaviors.same();
                })
                .onMessage(ClusterEvent.MemberRemoved.class, event -> {
                    log.info("Member is Removed: {} after {}", event.member(), event.previousStatus());
                    return Behaviors.same();
                })
                .onMessage(ClusterEvent.MemberDowned.class, event -> {
                    log.info("Member is Down: {}", event.member());
                    return Behaviors.same();
                })
                .onMessage(ClusterEvent.UnreachableMember.class, event -> {
                    log.info("Member detected as unreachable: {}", event.member());
                    return Behaviors.same();
                })
                .onMessage(ClusterEvent.ReachableMember.class, event -> {
                    log.info("Member detected as reachable: {}", event.member());
                    return Behaviors.same();
                })
                .onMessage(ClusterEvent.ClusterDomainEvent.class, event -> {
                    // Ignore other events
                    return Behaviors.same();
                })
                .build();
    }
}
