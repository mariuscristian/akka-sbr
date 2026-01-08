package com.example.akka.sbr;

import akka.actor.typed.ActorSystem;
import akka.actor.typed.Behavior;
import akka.actor.typed.javadsl.Behaviors;
import akka.management.javadsl.AkkaManagement;
import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;

public class Main {
    public static void main(String[] args) {
        // Load config to potentially override with system properties
        Config config = ConfigFactory.load();

        ActorSystem<Void> system = ActorSystem.create(rootBehavior(), "sbr-demo", config);

        // Start Akka Management (provides HTTP endpoint)
        AkkaManagement.get(system).start();

        // In this manual setup with seed-nodes, Cluster Bootstrap is not strictly
        // needed
        // but often good practice. Here we rely on seed-nodes in application.conf
    }

    private static Behavior<Void> rootBehavior() {
        return Behaviors.setup(context -> {
            context.spawn(ClusterListener.create(), "ClusterListener");
            return Behaviors.empty();
        });
    }
}
