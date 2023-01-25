// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:collection';
import 'package:fml/observable/observable.dart';
import 'package:fml/observable/scope.dart';
import 'package:fml/helper/common_helpers.dart';

class ScopeManager
{
  HashMap<String?, List<Scope>>  directory  = HashMap<String?,List<Scope>>();
  HashMap<String?, List<Observable>>? unresolved;

  ScopeManager();

  add(Scope scope, {String? alias})
  {
    var id = scope.id;
    if (alias != null) id = alias;
    
    if (!directory.containsKey(id)) directory[id] = [];
    if (!directory[id]!.contains(scope)) directory[id]!.add(scope);
  }

  remove(Scope scope)
  {
    if ((directory.containsKey(scope.id)) && (directory[scope.id]!.contains(scope))) directory[scope.id]!.remove(scope);
    if (unresolved != null)
    {
      unresolved!.removeWhere((scopeId, observable) => scopeId == scope.id);
      if (unresolved!.isEmpty) unresolved = null;
    }
  }

  Scope? of(String? id)
  {
    if (id == null) return null;
    if (directory.containsKey(id)) return directory[id]!.last;
    return null;
  }

  register(Observable observable)
  {
    if ((S.isNullOrEmpty(observable.key)) || (observable.scope == null)) return null;

    // Notify 
    _notifyDescendants(observable.scope!, observable);

    // Unresolved Named Scope 
    if (unresolved != null) _notifyUnresolved(observable.scope!.id);
  }

  void _notifyUnresolved(String? scopeId)
  {
    if (unresolved!.containsKey(scopeId))
    {
      List<Observable> targets = [];
      unresolved![scopeId]!.forEach((observable) => targets.add(observable));
      unresolved!.remove(scopeId);
      targets.forEach((observable) => observable.scope!.bind(observable));
    }
  }

  void _notifyDescendants(Scope scope, Observable observable)
  {
    // Resolve 
    if (scope.unresolved.containsKey(observable.key))
    {
      List<Observable> unresolved = scope.unresolved[observable.key]!.toList(growable: false);
      unresolved.forEach((target) => scope.bind(target));
    }

    // Resolve Children 
    if (scope.children != null)
      scope.children!.forEach((scope) => _notifyDescendants(scope, observable));
  }

  Observable? named(Observable? target, String? scopeId, String? observableKey)
  {
    // Find Scope 
    Scope? scope = directory.containsKey(scopeId) ? directory[scopeId]!.last : null;

    // Find Observable in Scope 
    Observable? observable;
    if (scope != null) observable = scope.observables.containsKey(observableKey) ? scope.observables[observableKey] : null;

    // Not Found 
    if ((observable == null) && (target != null) && (target.scope != null))
    {
      // Create New Unresolved 
      if (unresolved == null) unresolved = HashMap<String?, List<Observable>>();

      // Create New Unresolved Scope 
      if (!unresolved!.containsKey(scopeId)) unresolved![scopeId] = [];

      // Create New Unresolved Scope Target 
      if (!unresolved![scopeId]!.contains(target)) unresolved![scopeId]!.add(target);
    }

    return observable;
  }

  Observable? scoped(Scope? scope, String? key)
  {
    if ((scope == null) || (S.isNullOrEmpty(key))) return null;
    if (scope.observables.containsKey(key)) return scope.observables[key];
    return scoped(scope.parent, key);
  }
}