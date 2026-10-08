#1 Student Performance Analysis by Study Habits and Consistency

WITH study_groups AS (
    SELECT
        CASE
            WHEN study_hours_per_day < 1 THEN 'Less than 1 hour'
            WHEN study_hours_per_day < 2 THEN '1-2 hours'
            WHEN study_hours_per_day < 4 THEN '2-4 hours'
            ELSE '4+ hours'
        END AS study_hours_group,

        CASE
            WHEN self_study_hours < 1 THEN 'Less than 1 hour'
            WHEN self_study_hours < 2 THEN '1-2 hours'
            WHEN self_study_hours < 3 THEN '2-3 hours'
            ELSE '3+ hours'
        END AS self_study_group,

        study_consistency,
        exam_score,
        previous_exam_score,
        assignment_completion_rate

    FROM students
),

performance_summary AS (
    SELECT
        study_hours_group,
        study_consistency,

        COUNT(*) AS student_count,

        ROUND(AVG(exam_score), 2) AS average_exam_score,

        ROUND(AVG(previous_exam_score), 2) AS average_previous_score,

        ROUND(AVG(assignment_completion_rate), 2)
            AS average_assignment_completion,

        ROUND(AVG(exam_score - previous_exam_score), 2)
            AS average_score_change

    FROM study_groups

    GROUP BY
        study_hours_group,
        study_consistency
)

SELECT
    study_hours_group,
    study_consistency,
    student_count,
    average_exam_score,
    average_previous_score,
    average_score_change,
    average_assignment_completion,

    RANK() OVER (
        ORDER BY average_exam_score DESC
    ) AS performance_rank

FROM performance_summary

WHERE student_count >= 100

ORDER BY performance_rank;



#2 Student Performance Analysis by Stress Levels

SELECT
    stress_level,

    COUNT(*) AS student_count,

    ROUND(
        AVG(exam_anxiety_level),
        2
    ) AS average_exam_anxiety,

    ROUND(
        AVG(exam_score),
        2
    ) AS average_exam_score,

    ROUND(
        AVG(previous_exam_score),
        2
    ) AS average_previous_score,

    ROUND(
        AVG(exam_score - previous_exam_score),
        2
    ) AS average_score_change,

    ROUND(
        AVG(
            CASE
                WHEN pass_status = 'Pass'
                THEN 1.0
                ELSE 0.0
            END
        ) * 100,
        2
    ) AS pass_rate_percentage

FROM students

GROUP BY stress_level

ORDER BY stress_level;




#3 Student Performance Analysis by Study Habits and Consistency

WITH performance_change AS (
    SELECT
        student_id,
        previous_exam_score,
        exam_score,

        exam_score - previous_exam_score
            AS score_change,

        assignment_completion_rate,
        study_hours_per_day,
        study_consistency,
        practice_tests_completed

    FROM students
),

student_segments AS (
    SELECT
        *,
        CASE
            WHEN previous_exam_score < 60
                THEN 'Previously Low'

            WHEN previous_exam_score < 75
                THEN 'Previously Moderate'

            WHEN previous_exam_score < 90
                THEN 'Previously Strong'

            ELSE 'Previously Excellent'
        END AS previous_performance_group
    FROM performance_change
)

SELECT
    previous_performance_group,

    COUNT(*) AS student_count,

    ROUND(
        AVG(previous_exam_score),
        2
    ) AS average_previous_score,

    ROUND(
        AVG(exam_score),
        2
    ) AS average_current_score,

    ROUND(
        AVG(score_change),
        2
    ) AS average_score_change,

    ROUND(
        AVG(study_hours_per_day),
        2
    ) AS average_daily_study_hours,

    ROUND(
        AVG(assignment_completion_rate),
        2
    ) AS average_assignment_completion,

    ROUND(
        AVG(practice_tests_completed),
        2
    ) AS average_practice_tests

FROM student_segments

GROUP BY previous_performance_group

ORDER BY
    average_previous_score;





#4 Student Performance Analysis by Practice Test Completion

WITH practice_analysis AS (
    SELECT
        CASE
            WHEN practice_tests_completed = 0
                THEN 'No Practice Tests'

            WHEN practice_tests_completed BETWEEN 1 AND 2
                THEN '1-2 Tests'

            WHEN practice_tests_completed BETWEEN 3 AND 5
                THEN '3-5 Tests'

            WHEN practice_tests_completed BETWEEN 6 AND 10
                THEN '6-10 Tests'

            ELSE '10+ Tests'
        END AS practice_test_group,

        exam_score,
        previous_exam_score,
        exam_anxiety_level,
        time_management_score,
        questions_correct,
        questions_attempted

    FROM students
)

SELECT
    practice_test_group,

    COUNT(*) AS student_count,

    ROUND(
        AVG(exam_score),
        2
    ) AS average_exam_score,

    ROUND(
        AVG(exam_score - previous_exam_score),
        2
    ) AS average_score_improvement,

    ROUND(
        AVG(exam_anxiety_level),
        2
    ) AS average_exam_anxiety,

    ROUND(
        AVG(time_management_score),
        2
    ) AS average_time_management_score,

    ROUND(
        AVG(
            questions_correct::NUMERIC
            / NULLIF(questions_attempted, 0)
            * 100
        ),
        2
    ) AS average_question_accuracy

FROM practice_analysis

GROUP BY practice_test_group

ORDER BY
    MIN(
        CASE practice_test_group
            WHEN 'No Practice Tests' THEN 0
            WHEN '1-2 Tests' THEN 1
            WHEN '3-5 Tests' THEN 2
            WHEN '6-10 Tests' THEN 3
            ELSE 4
        END
    );





#5 Student Performance Analysis by Risk Category

SELECT
    student_id,
    age,
    education_level,
    previous_exam_score,
    exam_score,

    ROUND(
        exam_score - previous_exam_score,
        2
    ) AS score_change,

    assignment_completion_rate,
    study_hours_per_day,
    study_consistency,

    practice_tests_completed,
    time_management_score,

    stress_level,
    exam_anxiety_level,

    sleep_hours,

    pass_status,
    performance_level,

    CASE
        WHEN exam_score < 50
             AND stress_level >= 8
             AND exam_anxiety_level >= 8
            THEN 'Critical Risk'

        WHEN exam_score < 50
             AND assignment_completion_rate < 60
            THEN 'High Risk'

        WHEN exam_score < 60
             OR time_management_score < 50
             OR study_consistency = 'Low'
            THEN 'Moderate Risk'

        ELSE 'Low Risk'
    END AS risk_category

FROM students

WHERE
    exam_score < 60
    OR stress_level >= 8
    OR exam_anxiety_level >= 8
    OR assignment_completion_rate < 60
    OR time_management_score < 50

ORDER BY
    CASE
        WHEN exam_score < 50
             AND stress_level >= 8
             AND exam_anxiety_level >= 8
            THEN 1

        WHEN exam_score < 50
             AND assignment_completion_rate < 60
            THEN 2

        WHEN exam_score < 60
             OR time_management_score < 50
             OR study_consistency = 'Low'
            THEN 3

        ELSE 4
    END,

    exam_score ASC;