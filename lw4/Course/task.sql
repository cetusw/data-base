CREATE DATABASE course;
USE course;

#2.1 Извлечь имена всех активных пользователей, которые правильно ответили на все вопросы
# готового к использованию квиза с названием <ваше название>. Квиз должен быть
# не удалённым курсом. Если у пользователя нет имени, отображать его email.

SELECT DISTINCT IF(u.name IS NOT NULL, u.name, u.email) AS user
FROM user u
         INNER JOIN enrollment e ON u.user_id = e.user_id
         INNER JOIN course c ON e.course_id = c.course_id
         INNER JOIN quiz q ON c.course_id = q.quiz_id
         INNER JOIN quiz_question qq ON q.quiz_id = qq.quiz_id
         INNER JOIN attempt a ON e.enrollment_id = a.enrollment_id
         INNER JOIN quiz_attempt_answer qaa ON a.attempt_id = qaa.attempt_id
    AND qq.question_id = qaa.question_id
         LEFT JOIN multiple_choice_question_available_values mcqav ON qq.question_id = mcqav.question_id
    AND qq.question_type = 'MCQAV'
         LEFT JOIN sequence_question_available_values sqav ON qq.question_id = sqav.question_id
    AND qq.question_type = 'SQAV'
WHERE u.state = 'ACTIVE'
  AND c.deleted_at IS NULL
  AND c.name = 'Course 32'
  AND q.state = 'READY'
  AND ((qq.question_type = 'MCQAV' AND qaa.answer_value = mcqav.value AND mcqav.is_correct = 1)
    OR (qq.question_type = 'SQAV' AND qaa.answer_value = sqav.value AND qaa.answer_value_order = sqav.value_order));


#2.2 Извлечь все прохождения, не пройденные до конца (когда один или несколько вопросов не пройдены).
# Нужно извлечь имена пользователей и курсов, в которых есть такая ситуация.
# Пара пользователь - курс не должна дублироваться.

SELECT DISTINCT IF(u.name IS NOT NULL, u.name, u.email) user_with_uncompleted_course,
                c.name                                  course_name
FROM user u
         INNER JOIN enrollment e ON u.user_id = e.user_id
         INNER JOIN course c ON e.course_id = c.course_id
         INNER JOIN attempt a ON e.enrollment_id = a.enrollment_id
         INNER JOIN quiz_attempt_answer qaa ON a.attempt_id = qaa.attempt_id
WHERE qaa.answer_value = '';


#2.3 Подсчитать среднее количество вопросов в квизе, на которые правильно ответили уволенные пользователи
# в период до 2025, а также посчитать посчитать среднее количество вопросов в квизе,
# на которые правильно ответили активные пользователи в период за 2025. И сделать текстовый вывод,
# кто проходит квизы лучше. Сделать в единый SQL запрос

SELECT IF(fired_avg > active_avg,
          'FIRED users answered more questions correctly before 2025.',
          IF(active_avg > fired_avg,
             'ACTIVE users answered more questions correctly in 2025.',
             'Both user groups performed equally.')
       )                    AS comparison_result,
       ROUND(fired_avg, 2)  AS avg_correct_fired,
       ROUND(active_avg, 2) AS avg_correct_active
FROM (SELECT AVG(correct_answers) AS fired_avg
      FROM (SELECT COUNT(*) AS correct_answers
            FROM quiz_attempt_answer qaa
                     JOIN attempt a ON a.attempt_id = qaa.attempt_id
                     JOIN enrollment e ON e.enrollment_id = a.enrollment_id
                     JOIN quiz_question qq ON qq.question_id = qaa.question_id
                     LEFT JOIN multiple_choice_question_available_values mcqav ON qq.question_id = mcqav.question_id
                AND qq.question_type = 'MCQAV'
                     LEFT JOIN sequence_question_available_values sqav ON qq.question_id = sqav.question_id
                AND qq.question_type = 'SQAV'
                     JOIN user u ON u.user_id = e.user_id
            WHERE u.state = 'FIRED'
              AND a.start_date < '2025-01-01'
              AND ((qq.question_type = 'MCQAV' AND qaa.answer_value = mcqav.value AND mcqav.is_correct = 1)
                OR (qq.question_type = 'SQAV' AND qaa.answer_value = sqav.value AND
                    qaa.answer_value_order = sqav.value_order))
            GROUP BY a.attempt_id) AS fired_data) AS fired_result,
     (SELECT AVG(correct_answers) AS active_avg
      FROM (SELECT COUNT(*) AS correct_answers
            FROM quiz_attempt_answer qaa
                     JOIN attempt a ON a.attempt_id = qaa.attempt_id
                     JOIN enrollment e ON e.enrollment_id = a.enrollment_id
                     JOIN quiz_question qq ON qq.question_id = qaa.question_id
                     LEFT JOIN multiple_choice_question_available_values mcqav ON qq.question_id = mcqav.question_id
                AND qq.question_type = 'MCQAV'
                     LEFT JOIN sequence_question_available_values sqav ON qq.question_id = sqav.question_id
                AND qq.question_type = 'SQAV'
                     JOIN user u ON u.user_id = e.user_id
            WHERE u.state = 'ACTIVE'
              AND a.start_date >= '2025-01-01'
              AND a.start_date < '2026-01-01'
              AND ((qq.question_type = 'MCQAV' AND qaa.answer_value = mcqav.value AND mcqav.is_correct = 1)
                OR (qq.question_type = 'SQAV' AND qaa.answer_value = sqav.value AND
                    qaa.answer_value_order = sqav.value_order))
            GROUP BY a.attempt_id) AS active_data) AS active_result;
