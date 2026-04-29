CREATE DATABASE task_management;

-- Шаг 3: Создание схемы для приложения
CREATE SCHEMA app;

-- Шаг 4: Создание таблиц
-- Таблица пользователей (в реальном проекте используйте pg_authid)
CREATE TABLE app.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица проектов
CREATE TABLE app.projects (
    project_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES app.users(user_id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица задач
CREATE TABLE app.tasks (
    task_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES app.projects(project_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
    priority INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    assignee_id INTEGER REFERENCES app.users(user_id),
    created_by INTEGER REFERENCES app.users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица комментариев к задачам
CREATE TABLE app.comments (
    comment_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    user_id INTEGER REFERENCES app.users(user_id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица истории изменений задач (для аудита)
CREATE TABLE app.task_history (
    history_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    changed_by INTEGER REFERENCES app.users(user_id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    field_name VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT
);

-- Таблица логов доступа (для аудита)
CREATE TABLE app.access_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app.users(user_id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    ip_address INET,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO app.users (username, email, password_hash, full_name) VALUES
('geralt_riv', 'white.wolf@kaermorhen.pl', 'hash1', 'Geralt of Rivia'),
('tony_stark', 'ironman@starkindustries.com', 'hash2', 'Tony Stark'),
('b_wayne', 'darkknight@waynecorp.com', 'hash3', 'Bruce Wayne'),
('p_parker', 'spidey@dailybugle.nyc', 'hash4', 'Peter Parker'),
('n_drake', 'nate@fortune-hunter.org', 'hash5', 'Nathan Drake'),
('m_sub-zero', 'grandmaster@lin-kuei.io', 'hash6', 'Kuai Liang'),
('c_johnson', 'cj@grove-street.ls', 'hash7', 'Carl Johnson'),
('m_shepard', 'commander@n7.citadel', 'hash8', 'John Shepard'),
('kratos_god', 'ghost@sparta.gr', 'hash9', 'Kratos of Sparta'),
('solid_snake', 'snake@foxhound.gov', 'hash10', 'David Pliskin'),
('dante_son', 'pizza@devil-may-cry.biz', 'hash11', 'Dante Alighieri'),
('l_lawliet', 'justice@watari.mail', 'hash12', 'L Lawliet'),
('m_morales', 'miles@brooklyn.vision', 'hash13', 'Miles Morales'),
('j_wick', 'babayaga@continental.hotel', 'hash14', 'John Wick'),
('a_wake', 'writer@brightfalls.com', 'hash15', 'Alan Wake'),
('doom_slayer', 'rip_tear@mars.uac', 'hash16', 'Flynn Taggart'),
('claire_r', 'claire@terrasave.org', 'hash17', 'Claire Redfield'),
('j_miller', 'joel@tlou.fireflies', 'hash18', 'Joel Miller'),
('v_cyber', 'v@afterlife.nc', 'hash19', 'Vincent Valenti'),
('s_samus', 'hunter@galactic.fed', 'hash20', 'Samus Aran');

INSERT INTO app.projects (name, description, owner_id, status) VALUES
('Stark Tower Security', 'Upgrade AI defense systems and arc reactor monitoring', 2, 'active'),
('Kaer Morhen Restoration', 'Renovate the old keep and fix the training grounds', 1, 'active'),
('Wayne Enterprise Cloud', 'Migrate sensitive data to a secure underground server', 3, 'active'),
('Daily Bugle App', 'Create a mobile platform for freelance photography uploads', 4, 'active');

INSERT INTO app.tasks (project_id, title, description, status, priority, assignee_id, created_by) VALUES
(1, 'AI Core Calibration', 'Calibrate the arc reactor output for Stark Tower security', 'in_progress', 1, 2, 2),
(1, 'Peripheral Cameras', 'Install 360-degree motion sensors on the roof', 'todo', 2, 1, 2),
(2, 'Wall Fortification', 'Reinforce the south-western wall of the keep', 'todo', 1, 1, 1),
(2, 'Alchemy Lab Setup', 'Organize potions and monster decoctions in the basement', 'done', 3, 1, 1),
(3, 'Encrypted Layer 7', 'Apply extra encryption to the Batcave private cloud', 'in_progress', 1, 3, 3),
(4, 'Photo Upload Engine', 'Optimize image compression for faster news delivery', 'todo', 2, 4, 4),
(4, 'User UI Feedback', 'Implement comments section for Daily Bugle readers', 'todo', 3, 4, 4);

SELECT owner_id, name FROM app.projects;
TRUNCATE app.users, app.projects, app.tasks RESTART IDENTITY CASCADE;

-- Роль "Гость" - минимальные права
CREATE ROLE app_guest;

-- Роль "Сотрудник" - базовые права сотрудника
CREATE ROLE app_employee;

-- Роль "Менеджер" - наследует права сотрудника
CREATE ROLE app_manager;

-- Роль "Администратор" - наследует права менеджера
CREATE ROLE app_admin;

-- Роль "Суперпользователь" - полные права
CREATE ROLE app_superuser;

-- Гость: только подключение к БД
GRANT CONNECT ON DATABASE task_management TO app_guest;
GRANT USAGE ON SCHEMA app TO app_guest;

-- Сотрудник: подключение и использование схемы
GRANT CONNECT ON DATABASE task_management TO app_employee;
GRANT USAGE ON SCHEMA app TO app_employee;

-- Гость может видеть только публичные проекты
GRANT SELECT ON TABLE app.projects TO app_guest;

-- Чтение данных о пользователях (ограничено)
GRANT SELECT (user_id, username, full_name) ON TABLE app.users TO app_employee;

-- Чтение проектов и задач
GRANT SELECT ON TABLE app.projects TO app_employee;
GRANT SELECT ON TABLE app.tasks TO app_employee;

-- Создание и редактирование своих задач
GRANT SELECT, INSERT ON TABLE app.tasks TO app_employee;
GRANT USAGE ON SEQUENCE app.tasks_task_id_seq TO app_employee;

-- Комментарии: чтение и создание
GRANT SELECT, INSERT ON TABLE app.comments TO app_employee;
GRANT USAGE ON SEQUENCE app.comments_comment_id_seq TO app_employee;

-- Чтение своей истории
GRANT SELECT ON TABLE app.task_history TO app_employee;

-- Наследование прав сотрудника
GRANT app_employee TO app_manager;

-- Полный доступ к проектам (своим)
GRANT SELECT, INSERT, UPDATE ON TABLE app.projects TO app_manager;

-- Полный доступ к задачам в своих проектах
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.tasks TO app_manager;

-- Доступ к комментариям
GRANT SELECT, INSERT, DELETE ON TABLE app.comments TO app_manager;

-- Просмотр истории изменений
GRANT SELECT ON TABLE app.task_history TO app_manager;

-- Запись в историю изменений
GRANT INSERT ON TABLE app.task_history TO app_manager;


-- Наследование прав менеджера
GRANT app_manager TO app_admin;

-- Администратор управляет пользователями
GRANT SELECT, INSERT, UPDATE ON TABLE app.users TO app_admin;

-- Полный доступ ко всем таблицам
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_admin;

-- Право создавать объекты в схеме
GRANT CREATE ON SCHEMA app TO app_admin;


-- Наследование прав администратора
GRANT app_admin TO app_superuser;

-- Суперпользователь имеет все права в БД
GRANT ALL PRIVILEGES ON DATABASE task_management TO app_superuser;


-- Создание пользователей с паролями
CREATE USER alice WITH PASSWORD 'AliceSecure123!';
CREATE USER bob WITH PASSWORD 'BobSecure456!';
CREATE USER charlie WITH PASSWORD 'CharlieSecure789!';
CREATE USER diana WITH PASSWORD 'DianaSecure012!';
CREATE USER eve WITH PASSWORD 'EveSecure345!';


-- Назначение ролей пользователям
-- Alice - менеджер проекта
GRANT app_manager TO alice;

-- Bob и Charlie - сотрудники
GRANT app_employee TO bob;
GRANT app_employee TO charlie;

-- Diana - администратор
GRANT app_admin TO diana;

-- Eve - суперпользователь (для тестирования)
GRANT app_superuser TO eve;

SELECT 
    rolname AS role_name,
    rolsuper AS is_superuser,
    rolcreaterole AS can_create_role,
    rolcreatedb AS can_create_db,
    rolcanlogin AS can_login
FROM pg_catalog.pg_roles
WHERE rolname NOT LIKE 'pg_%' -- скрываем системные роли
ORDER BY rolname;

SELECT 
    m.rolname AS member_role, -- кто наследует
    r.rolname AS role_granted -- чьи права получил
FROM pg_auth_members am
JOIN pg_roles m ON am.member = m.oid
JOIN pg_roles r ON am.roleid = r.oid
WHERE m.rolname IN ('app_employee', 'app_manager', 'app_admin', 'app_superuser');

-- Просмотр прав роли
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('app_guest', 'app_employee', 'app_manager', 'app_admin', 'app_superuser')
ORDER BY grantee, table_name, privilege_type;

SELECT 
    m.rolname AS member_name,   -- Имя пользователя (например, alice)
    r.rolname AS role_name     -- Имя роли (например, app_manager)
FROM pg_auth_members am
JOIN pg_roles m ON am.member = m.oid
JOIN pg_roles r ON am.roleid = r.oid
WHERE r.rolname = 'app_manager'; -- Здесь укажи роль, которую проверяешь


-- =====================================================
-- ТЕСТИРОВАНИЕ RBAC-МОДЕЛИ В DBEAVER
-- =====================================================

-------------------------------------------------------
-- Тест 1: Сотрудник (Bob)
-------------------------------------------------------
SET ROLE bob;

-- 1.1. Должен видеть ограниченный список полей юзеров (если настраивали колонки)
SELECT user_id, username, full_name FROM app.users; 

-- 1.2. Пытаемся посмотреть хеши паролей (Должна быть ОШИБКА доступа)
SELECT password_hash FROM app.users; 

-- 1.3. Просмотр проектов и задач (Должно работать)
SELECT * FROM app.projects;
SELECT * FROM app.tasks;

-- 1.4. Создание своей задачи (Должно работать)
INSERT INTO app.tasks (project_id, title, description, priority, assignee_id, created_by)
VALUES (1, 'Task by Bob', 'Permissions test', 3, 2, 2);

-- 1.5. Попытка удаления (Должна быть ОШИБКА)
DELETE FROM app.tasks WHERE project_id = 1;

RESET ROLE;

-------------------------------------------------------
-- Тест 2: Менеджер (Alice)
-------------------------------------------------------
SET ROLE alice;

-- 2.1. Менеджер может видеть историю (Должно работать)
SELECT * FROM app.task_history;

-- 2.2. Менеджер может обновлять задачи (Должно работать)
UPDATE app.tasks SET status = 'in_progress' WHERE title = 'Task by Bob';

-- 2.3. Менеджер НЕ может менять данные пользователей (Должна быть ОШИБКА)
UPDATE app.users SET full_name = 'Hacked' WHERE user_id = 1;

RESET ROLE;

-------------------------------------------------------
-- Тест 3: Администратор (Diana)
-------------------------------------------------------
SET ROLE diana;

-- 3.1. Админ может менять почту или имя юзера (Должно работать)
UPDATE app.users SET full_name = 'Robert Baratheon' WHERE username = 'bob';

-- 3.2. Админ может создать временную таблицу для тестов (Должно работать)
CREATE TABLE app.test_temp (id SERIAL PRIMARY KEY, val TEXT);
DROP TABLE app.test_temp;

RESET ROLE;

DROP TABLE IF EXISTS app.test_superuser;
CREATE TABLE app.test_superuser (id INT);
DROP TABLE app.test_superuser;

SELECT current_user, session_user;


-- 1. Становимся гостем
SET ROLE app_guest;

-- 3. ТЕСТ: Чтение проектов (Должно работать, если дали SELECT)
SELECT * FROM app.projects;

-- 4. ТЕСТ: Попытка залезть в задачи (Должна быть ОШИБКА)
-- У гостя нет прав на таблицу tasks
SELECT * FROM app.tasks;

-- 5. ТЕСТ: Попытка создать комментарий (Должна быть ОШИБКА)
INSERT INTO app.comments (task_id, user_id, content) 
VALUES (1, 1, 'Guest was here');

-- Возвращаемся
RESET ROLE;


-- 1. Становимся суперпользователем
SET ROLE eve;

-- 3. ТЕСТ: Просмотр всего, включая защищенные данные (Должно работать)
-- В отличие от Боба, Ив видит и пароли, и логи
SELECT * FROM app.users;
SELECT * FROM app.access_logs;

-- 4. ТЕСТ: Выполнение DDL (Изменение структуры)
-- Только админы и суперюзеры могут создавать таблицы
CREATE TABLE app.test_system (id INT, status TEXT);

-- 5. ТЕСТ: Удаление данных (Должно работать)
-- Очистим за собой
	DROP TABLE app.test_system;

-- 6. ТЕСТ: Манипуляция любыми проектами
-- Ив может менять даже те проекты, где она не owner
UPDATE app.projects SET status = 'archived' WHERE project_id = 1;

-- Возвращаемся
RESET ROLE;




-- Включаем RLS для таблицы задач
ALTER TABLE app.tasks ENABLE ROW LEVEL SECURITY;

-- Политика для сотрудников: видят только свои задачи или общие
CREATE POLICY employee_tasks_select ON app.tasks
    FOR SELECT
    TO app_employee
    USING (
        assignee_id = (SELECT user_id FROM app.users WHERE username = current_user)
        OR assignee_id IS NULL  -- Общие задачи без ответственного
    );

-- Политика для сотрудников: могут создавать только задачи на себя
CREATE POLICY employee_tasks_insert ON app.tasks
    FOR INSERT
    TO app_employee
    WITH CHECK (
        assignee_id = (SELECT user_id FROM app.users WHERE username = current_user)
        OR assignee_id IS NULL
    );

-- Политика для сотрудников: могут обновлять только свои задачи
CREATE POLICY employee_tasks_update ON app.tasks
    FOR UPDATE
    TO app_employee
    USING (
        assignee_id = (SELECT user_id FROM app.users WHERE username = current_user)
    );

-- -----------------------------------------------------
-- Политика 2: Менеджеры видят все задачи в своих проектах
-- -----------------------------------------------------

-- Политика для менеджеров: полный доступ к задачам
CREATE POLICY manager_tasks_all ON app.tasks
    FOR ALL
    TO app_manager
    USING (TRUE)  -- Менеджеры видят всё
    WITH CHECK (TRUE);

-- -----------------------------------------------------
-- Политика 3: Пользователи видят только свои данные
-- -----------------------------------------------------

ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

-- Сотрудники видят только базовую информацию о всех
CREATE POLICY users_employee_select ON app.users
    FOR SELECT
    TO app_employee
    USING (TRUE)  -- Видят всех, но только разрешенные колонки

-- Обновление: только свои данные (для смены профиля)
CREATE POLICY users_employee_update ON app.users
    FOR UPDATE
    TO app_employee
    USING (
        username = current_user
    );

-- -----------------------------------------------------
-- Проверка RLS
-- -----------------------------------------------------

-- Подключиться как bob и проверить
-- \c task_management bob

-- Bob видит только свои задачи
SELECT * FROM app.tasks;

-- Попытка обновить чужую задачу должна быть заблокирована RLS
UPDATE app.tasks SET priority = 1 WHERE task_id = 1;
-- ОШИБКА: новые строки не удовлетворяют проверочному выражению политики
