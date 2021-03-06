import 'dart:io';

import 'package:custed2/core/lisp/lisp_exceptions.dart';
import 'package:custed2/core/lisp/lisp_interp.dart';
import 'package:custed2/core/lisp_module/module.dart';
import 'package:custed2/core/tty/exception.dart';
import 'package:custed2/locator.dart';
import 'package:custed2/service/custed_service.dart';
import 'package:path/path.dart' as path;

class LMCoreBase extends LModule {
  LMCoreBase(LispInterp interp) : super(interp);

  static const source = '''
(setq defmacro
      (macro (name args &rest body)
             `(progn (setq ,name (macro ,args ,@body))
                     ',name)))
(defmacro defun (name args &rest body)
  `(progn (setq ,name (lambda ,args ,@body))
          ',name))
(defun caar (x) (car (car x)))
(defun cadr (x) (car (cdr x)))
(defun cdar (x) (cdr (car x)))
(defun cddr (x) (cdr (cdr x)))
(defun caaar (x) (car (car (car x))))
(defun caadr (x) (car (car (cdr x))))
(defun cadar (x) (car (cdr (car x))))
(defun caddr (x) (car (cdr (cdr x))))
(defun cdaar (x) (cdr (car (car x))))
(defun cdadr (x) (cdr (car (cdr x))))
(defun cddar (x) (cdr (cdr (car x))))
(defun cdddr (x) (cdr (cdr (cdr x))))
(defun not (x) (eq x nil))
(defun consp (x) (not (atom x)))
(defun print (x) (prin1 x) (terpri) x)
(defun identity (x) x)
(setq
 = eql
 rem %
 null not
 setcar rplaca
 setcdr rplacd)
(defun > (x y) (< y x))
(defun >= (x y) (not (< x y)))
(defun <= (x y) (not (< y x)))
(defun /= (x y) (not (= x y)))
(defun equal (x y)
  (cond ((atom x) (eql x y))
        ((atom y) nil)
        ((equal (car x) (car y)) (equal (cdr x) (cdr y)))))
(defmacro if (test then &rest else)
  `(cond (,test ,then)
         ,@(cond (else `((t ,@else))))))
(defmacro when (test &rest body)
  `(cond (,test ,@body)))
(defmacro let (args &rest body)
  ((lambda (vars vals)
     (defun vars (x)
       (cond (x (cons (if (atom (car x))
                          (car x)
                        (caar x))
                      (vars (cdr x))))))
     (defun vals (x)
       (cond (x (cons (if (atom (car x))
                          nil
                        (cadar x))
                      (vals (cdr x))))))
     `((lambda ,(vars args) ,@body) ,@(vals args)))
   nil nil))
(defmacro letrec (args &rest body)      ; (letrec ((v e) ...) body...)
  (let (vars setqs)
    (defun vars (x)
      (cond (x (cons (caar x)
                     (vars (cdr x))))))
    (defun sets (x)
      (cond (x (cons `(setq ,(caar x) ,(cadar x))
                     (sets (cdr x))))))
    `(let ,(vars args) ,@(sets args) ,@body)))
(defun _append (x y)
  (if (null x)
      y
    (cons (car x) (_append (cdr x) y))))
(defmacro append (x &rest y)
  (if (null y)
      x
    `(_append ,x (append ,@y))))
(defmacro and (x &rest y)
  (if (null y)
      x
    `(cond (,x (and ,@y)))))
(defun mapcar (f x)
  (and x (cons (f (car x)) (mapcar f (cdr x)))))
(defmacro or (x &rest y)
  (if (null y)
      x
    `(cond (,x)
           ((or ,@y)))))
(defun listp (x)
  (or (null x) (consp x)))    ; NB (listp (lambda (x) (+ x 1))) => nil
(defun memq (key x)
  (cond ((null x) nil)
        ((eq key (car x)) x)
        (t (memq key (cdr x)))))
(defun member (key x)
  (cond ((null x) nil)
        ((equal key (car x)) x)
        (t (member key (cdr x)))))
(defun assq (key alist)
  (cond (alist (let ((e (car alist)))
                 (if (and (consp e) (eq key (car e)))
                     e
                   (assq key (cdr alist)))))))
(defun assoc (key alist)
  (cond (alist (let ((e (car alist)))
                 (if (and (consp e) (equal key (car e)))
                     e
                   (assoc key (cdr alist)))))))
(defun _nreverse (x prev)
  (let ((next (cdr x)))
    (setcdr x prev)
    (if (null next)
        x
      (_nreverse next x))))
(defun nreverse (list)            ; (nreverse '(a b c d)) => (d c b a)
  (cond (list (_nreverse list nil))))
(defun last (list)
  (if (atom (cdr list))
      list
    (last (cdr list))))
(defun nconc (&rest lists)
  (if (null (cdr lists))
      (car lists)
    (if (null (car lists))
        (apply nconc (cdr lists))
      (setcdr (last (car lists))
              (apply nconc (cdr lists)))
      (car lists))))
(defmacro while (test &rest body)
  (let ((loop (gensym)))
    `(letrec ((,loop (lambda () (cond (,test ,@body (,loop))))))
       (,loop))))
(defmacro dolist (spec &rest body) ; (dolist (name list [result]) body...)
  (let ((name (car spec))
        (list (gensym)))
    `(let (,name
           (,list ,(cadr spec)))
       (while ,list
         (setq ,name (car ,list))
         ,@body
         (setq ,list (cdr ,list)))
       ,@(if (cddr spec)
             `((setq ,name nil)
               ,(caddr spec))))))
(defmacro dotimes (spec &rest body) ; (dotimes (name count [result]) body...)
  (let ((name (car spec))
        (count (gensym)))
    `(let ((,name 0)
           (,count ,(cadr spec)))
       (while (< ,name ,count)
         ,@body
         (setq ,name (+ ,name 1)))
       ,@(if (cddr spec)
             `(,(caddr spec))))))
  ''';

  Future<void> load() async {
    await interp.evalString(source, null);

    interp.def('load', 1, _loadFile, true);
    interp.def('hub', 1, _hub, true);
    interp.def('sleep', 1, _sleep);
    interp.def('interrupt', -1, _interrupt);
  }

  _sleep(List args) {
    final seconds = args[0];
    return Future.delayed(Duration(seconds: seconds));
  }

  _loadFile(args) async {
    final filename = args[0].toString();
    final filepath = path.join(interp.currentDir.path, filename);
    File file = File(filepath);
    if (!await file.exists()) {
      file = File(filepath + '.cl');
    }
    if (!await file.exists()) {
      throw LispEvalException('no such file', filename);
    }
    final code = await file.readAsString();
    return interp.evalString(code, null);
  }

  _interrupt(List args) {
    final reason = args[0]?.car?.toString() ?? "";
    throw TTYInterrupt(reason);
  }

  _hub(List args) async {
    final name = args[0].toString();
    final code = await locator<CustedService>().getScript(name);
    return interp.evalString(code, null);
  }
}
