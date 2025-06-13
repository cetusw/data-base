show databases;
use files_ns;

CREATE TABLE directory
(
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    lft        INT          NOT NULL,
    rgt        INT          NOT NULL,
    depth      INT          NOT NULL DEFAULT 0,
    created_at TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

# 0. Создание первой директории
INSERT INTO directory (name, lft, rgt, depth)
VALUES ('New Folder 1', 1, 2, 0);

# 1. Поддерева целиком
SELECT child.name,
       child.lft,
       child.rgt,
       child.depth
FROM directory parent
         JOIN directory child ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE parent.id = 1
ORDER BY child.lft;

# 2. Поиска конкретного листа
SET GLOBAL log_bin_trust_function_creators = 1;

CREATE FUNCTION subtree_size(dir_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci)
    RETURNS INT
BEGIN
    DECLARE l INT;
    DECLARE r INT;

    SELECT lft, rgt
    INTO l, r
    FROM directory
    WHERE name = dir_name;

    RETURN r - l - 1;
END;

DROP FUNCTION subtree_size;

SELECT name,
       lft,
       rgt,
       depth
FROM directory
WHERE subtree_size(name) = 0;

# 3. Вывода списка родителей
SELECT parent.name,
       parent.lft,
       parent.rgt,
       parent.depth
FROM directory child
         JOIN directory parent ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE child.id = 5
  AND parent.id != child.id
ORDER BY parent.lft;

# 4. Вывода списка всех соседних директорий (у которых общий родитель)
SELECT child.name,
       child.lft,
       child.rgt,
       child.depth
FROM directory parent
         JOIN directory child ON child.lft BETWEEN parent.lft AND parent.rgt
WHERE parent.id = 1
  AND child.depth = parent.depth + 1
ORDER BY child.lft;

# 5. Удаление поддерева
BEGIN;
DELETE
FROM directory
WHERE lft >= (SELECT lft
              FROM (SELECT lft FROM directory WHERE id = 2) t)
  AND rgt <= (SELECT rgt
              FROM (SELECT rgt FROM directory WHERE id = 2) t);
COMMIT;
ROLLBACK;

# 6. Вставку 3 элементов в одного родителя
CREATE PROCEDURE AddDirectory(
    IN parent_id INT,
    IN dir_name VARCHAR(255)
)
BEGIN
    DECLARE parent_rgt INT;
    DECLARE parent_depth INT;

    START TRANSACTION;

    SELECT rgt, depth
    INTO parent_rgt, parent_depth
    FROM directory
    WHERE id = parent_id;

    UPDATE directory
    SET rgt = rgt + 2
    WHERE rgt >= parent_rgt
    ORDER BY rgt DESC;

    UPDATE directory
    SET lft = lft + 2
    WHERE lft > parent_rgt
    ORDER BY lft DESC;

    INSERT INTO directory (name, lft, rgt, depth)
    VALUES (dir_name, parent_rgt, parent_rgt + 1, parent_depth + 1);
    COMMIT;
END;

DROP PROCEDURE IF EXISTS AddDirectory;


CALL AddDirectory(1, 'New Folder 2');
CALL AddDirectory(1, 'New Folder 3');
CALL AddDirectory(2, 'New Folder 4');
CALL AddDirectory(2, 'New Folder 5');
CALL AddDirectory(3, 'New Folder 6');
CALL AddDirectory(3, 'New Folder 7');

# 7. Удаление 2 элементов

CREATE PROCEDURE DeleteDirectory(
    IN dir_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE dir_rgt INT;
    DECLARE dir_lft INT;

    START TRANSACTION;

    SELECT rgt, lft
    INTO dir_rgt, dir_lft
    FROM directory
    WHERE name = dir_name;

    UPDATE directory
    SET rgt   = rgt - 1,
        lft   = lft - 1,
        depth = depth - 1
    WHERE lft > dir_lft
      AND rgt < dir_rgt;

    UPDATE directory
    SET lft = lft - 2
    WHERE lft > dir_rgt;

    UPDATE directory
    SET rgt = rgt - 2
    WHERE rgt > dir_rgt;

    DELETE FROM directory WHERE name = dir_name;
    COMMIT;
END;

DROP PROCEDURE IF EXISTS DeleteDirectory;

BEGIN;

CALL DeleteDirectory('New Folder 3');

ROLLBACK;

# 8. Перемещение элемента в другое поддерево
CREATE FUNCTION GetDirLeft(dir_id INT)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE lft INT;

    SELECT d.lft
    INTO lft
    FROM directory d
    WHERE id = dir_id;

    RETURN lft;
END;

CREATE FUNCTION GetDirRight(dir_id INT)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE rgt INT;

    SELECT d.rgt
    INTO rgt
    FROM directory d
    WHERE name = dir_id;

    RETURN rgt;
END;

DROP FUNCTION GetDirRight;

CREATE PROCEDURE MoveDirectory(
    IN moving_dir INT,
    IN new_parent_id INT
)
BEGIN
    SET @dir_id := moving_dir;
    SET @dir_lft := GetDirLeft(moving_dir);
    SET @dir_rgt := GetDirRight(moving_dir);
    SET @parent_id := new_parent_id;
    SET @parent_rgt := GetDirRight(new_parent_id);
    SET @dir_size := @dir_rgt - @dir_lft + 1;

    UPDATE directory
    SET lft  = 0 - lft,
        rgt = 0 - rgt
    WHERE lft >= @dir_lft
      AND rgt <= @dir_rgt;

-- step 2: decrease left and/or right position values of currently 'lower' items (and parents)

    UPDATE directory
    SET lft = lft - @dir_size
    WHERE lft > @dir_rgt;
    UPDATE directory
    SET rgt = rgt - @dir_size
    WHERE rgt > @dir_rgt;

-- step 3: increase left and/or right position values of future 'lower' items (and parents)

    UPDATE directory
    SET lft = lft + @dir_size
    WHERE lft >= IF(@parent_rgt > @dir_rgt, @parent_rgt - @dir_size, @parent_rgt);
    UPDATE directory
    SET rgt = rgt + @dir_size
    WHERE rgt >= IF(@parent_rgt > @dir_rgt, @parent_rgt - @dir_size, @parent_rgt);

-- step 4: move node (ant it's subnodes) and update it's parent item id

    UPDATE directory
    SET lft  = 0 - lft + IF(@parent_rgt > @dir_rgt, @parent_rgt - @dir_rgt - 1,
                                            @parent_rgt - @dir_rgt - 1 + @dir_size),
        rgt = 0 - rgt + IF(@parent_rgt > @dir_rgt, @parent_rgt - @dir_rgt - 1,
                                             @parent_rgt - @dir_rgt - 1 + @dir_size)
    WHERE lft <= 0 - @dir_lft
      AND rgt >= 0 - @dir_rgt;
END;

DROP PROCEDURE MoveDirectory;

CALL MoveDirectory(2, 6);

# Скопировать данные, удалить, вставить на новое место с теми же данными
# Или нужно перемещать поддерево?