# Event-driven Behavior Tree
This project is a plugin for Godot Engine 4.0+.

This documentation assumes knowledge of event driven behavior trees. Here is a good introductory article about them: [Game AI Pro: Chapter 6 The Behavior Tree Starter Kit](http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter06_The_Behavior_Tree_Starter_Kit.pdf).

This project is not complete and certainly has bugs. The most recent additions were the Subtree and Utility functions and they are probably the least stable.


## Features
 - Graphical interface for editing and debugging trees.
 - Event-driven architecture remembers running nodes and skips running all of the tree every tick.
 - Decorator nodes are implemented as node decorators, this means decorators are anexed to the BTNodes and modify their behavior internally. This makes trees prettier and easier to read.
 - Subtrees that improve organizing and reutilizing your trees.
 - Utility composite nodes and decorators for more complex behavior.
 - Flexible Parallel node for complex behavior and simple implementation.


## Installing
To get this addon working:
 - Download the latest release and copy the addons folder to your Godot project.
 - (Optional) In the bt_editor_plugin.gd script, add the folders for your custom BTNodes under `_paths`. Otherwise, the plugin will only find nodes inside its own folders.
 - Enable the plugin in the project settings.


# Using the addon
To use the Behavior Tree, you need:
 - a Behavior Tree Resource
 - a BTAgent

The Behavior Tree should be built and saved to disk using the Editor in the bottom panel. **The editor does not save the tree automatically when the project is saved nor when the game is started, you have to save manually.** Also beware, it does not ask confirmation if changes are not saved and you load another tree.

Currently creating trees through code is not supported. I believe it can be done, but the graphical editor is certainly much less work.

The BTAgent is a node that should be attached to your character/object in the scene tree. It should have a reference to a behavior tree resource.

Below, some of the main classes are briefly explained:


## BTAgent
The BTAgent needs to be ticked manually by the user and executes the tree once.

Before executing the tree, the agent checks if any of the monitors have been interrupted once. During execution, monitors are ignored and will only cause interruptions in the next tick.


## BTBlackboard
The BTAgent has a BTBlackboard, which is a special dictionary that is used by the tree and agent to comunicate. The keys in this dictionary can be monitored by certain nodes and decorators to interrupt the execution and go back to previous nodes.


## BTNode
BTNodes are the main structure of the behavior tree. They are executed sequentialy when the agent is ticked. Every time a node is run, its BTConditions are checked, if any of them results false, the BTNode fails execution, otherwise, the node is run and its `_execute_tick` method is called.

To add a custom BTNode it needs to have a unique `_get_bt_type_name`, and the plugin must be restarted before it recognizes the node.


## BTLeaf
To affect your agent, use BTLeafs. There are a few included in this project, but you probably will need to create your own.

You can use BTCallable to call methods on the BTAgent or any script extending it. It can take only one argument currently which is given by a BTExpression, so you can access the agent and its blackboard. This makes the BTCallable very flexible, but I'm not sure of it's performance, haven't tested it.

To pass Variables from the tree to the agent, use BTBlackboardSet, which sets a blackboard entry to a BTExpression result. This makes it very flexible too.

You can also create a custom BTLeaf to execute your action, to do this, you might need to override the following methods:
 - `_get_bt_type_name`
 - `_execute_tick`
 - `_setup_execution`
 - `_abort`
 - `_interrupt`
 - `_save_memory`

They are documented in bt_node.gd.

Have a look at bt_particle_emitter.gd for an example of a custom leaf.


## BTComposite
The BTComposite compounds various other nodes (leaves or composites) to create complex behaviors. Composites execute children in their `sibling_index` order, which is determined by the node's y position on the graph.

They respond to the result of the execution from each child in their `_execute_response` method.

For examples of composites have a look at bt_selector.gd, bt_sequence.gd and bt_parallel.gd.


## BTCondition
Conditions are evaluated when the node runs and when it's monitored blackboard values are changed. If any condition on a node fails, the node does not run and returns FAILURE to its parent.


## BTModifier
Modifiers are run whenever the BTNode reports results to its parent. They, well, modify the result that will be reported to parent. Can be helpful to make a branch of the tree optional, for example.


## BTCompositeUtility
Very similar to composite, but uses its children's utility values to determine the order of execution. Utility values are extracted from the children's BTUtility decorators. In the composites folder, bt_utility.gd, bt_composite_utility.gd, bt_utility_selector.gd and bt_utility_sequence.gd have a bit more documentations on this. Composite Utilities can be monitored for changes in the order of children.


## BTSubtree
Subtree is a special leaf node that runs another tree as if it were part of the tree, like substituting the subtree node for the subtree. Setting the subtree during runtime is not currently supported but is a planned feature, so coming soon.


# Debugging
To see debug information of an agent, set its debug variable to true and open the bottom panel while the game is running in debug mode. `RUNNING` nodes will mark their left port as yellow, `SUCCESS` is green and `FAILURE` is red. The colors can be customized in graph/bt_graph_edit.gd.

If you have unsaved changes in your behavior tree editor when enabling debug on an agent, you might lose them. Remember to save before opening the game.

If more than one agent has debug = true, the debug information of both will be shown flickering between them. Be sure to turn one off before turning another debug on.

# Contributing
Any help is welcome, but discussing changes via Issue is preferred before opening a Pull Request. Please follow the [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) on your submissions.

Also, this is my first open source project, so any help with runnning a project like this is also welcome.