// CryptoJS methods to convince TypeScript not to throw errors
var CryptoJS;

/** Iterates through all properties that belong to an object. */
Object.prototype.eachOwnProperty = function (f) {
    for (var k in this)
        if (Object.prototype.hasOwnProperty.call(this, k))
            f(k, this[k]);
};

/** Map through all properties that belong to an object, returning an array.. */
Object.prototype.mapOwnProperties = function (f) {
    var newList = [];

    for (var k in this)
        if (Object.prototype.hasOwnProperty.call(this, k))
            newList[newList.length] = f(k, this[k]);

    return newList;
};

// Aliases for common DOM traversal functions
HTMLElement.prototype.find = HTMLElement.prototype.querySelectorAll;

HTMLElement.prototype.attr = HTMLElement.prototype.getAttribute;

HTMLElement.prototype.findClass = HTMLElement.prototype.getElementsByClassName;

HTMLElement.prototype.findTag = HTMLElement.prototype.getElementsByTagName;

NodeList.prototype.splice = function (idx) {
    var newList = [];

    for (var i = idx; i < this.length; i++) {
        newList[newList.length] = this[i];
    }

    return newList;
};

NodeList.prototype.map = function (f) {
    var newList = [];

    for (var i = 0; i < this.length; i++) {
        newList[i] = f(this[i]);
    }

    return newList;
};

NodeList.prototype.toArray = function () {
    var newList = [];

    for (var i = 0; i < this.length; i++) {
        newList[i] = this[i];
    }

    return newList;
};

/** Returns only the numeric elements of an array. */
Array.prototype.numerics = function () {
    return this.filter(function (x) {
        return !isNaN(x);
    });
};

/** Adds up the numeric elements of an array. */
Array.prototype.sum = function () {
    var numerics = this.numerics();
    if (numerics.length === 0)
        return NaN;
    return numerics.reduce(function (x, y) {
        return x + y;
    });
};

/** Returns the average of the numeric elements of an array. */
Array.prototype.average = function () {
    var numerics = this.numerics();
    if (numerics.length === 0)
        return NaN;
    return numerics.sum() / numerics.length();
};

/** A map with two arrays in parallel. */
Array.prototype.pmap = function (otherArray, f) {
    if (this.length !== otherArray.length)
        throw new Error('Array length mismatch.');

    var newList = [];
    for (var i = 0; i < this.length; i++)
        newList[i] = f(this[i], otherArray[i]);

    return newList;
};

/** Returns the weighted average of the numeric elements of an array. */
Array.prototype.weightedAverage = function (weights) {
    var numerics = this.numerics();
    var weightNums = weights.numerics();

    if (numerics.length !== weightNums.length || numerics.length === 0)
        return NaN;

    return numerics.pmap(weightNums, function (x, y) {
        return x * y;
    }) / weightNums.sum();
};

/** Flattens an array of arrays into an array. */
Array.prototype.flatten = function () {
    var newList = [];

    this.forEach(function (x) {
        if (x.length)
            x.forEach(function (y) {
                return newList[newList.length] = y;
            });
    });

    return newList;
};
/// <reference path='data.ts'/>
/// <reference path='qmath.ts'/>
var GPACalc;
(function (GPACalc) {
    var DEFAULT_GPA_PRECISION = 4;

    /**
    * Finds the grade point from a grade. To find the unweighted grade point,
    * specify offset = 0. To find weighted on 5.0 scale, specify offset = 1. To
    * find weighted on 6.0 scale, specify offset = 2.
    */
    function gradePoint(grade, offset) {
        if (isNaN(grade))
            return NaN;
        if (grade < 70)
            return 0;
        return Math.min((grade - 60) / 10, 4) + offset;
    }

    /** Calculates the unweighted grade point average of a list of courses. */
    function unweighted(grades) {
        return grades.map(function (x) {
            return x.semesters.map(function (y) {
                return gradePoint(y.average, 0);
            });
        }).flatten().average();
    }
    GPACalc.unweighted = unweighted;

    /**
    * Calculates the weighted grade point average of a list of courses, given a
    * list of courses that should be treated as honors and a bonus for honors
    * courses.
    */
    function weighted(grades, honors, honorsOffset) {
        return grades.map(function (x) {
            var offset = (honors.indexOf(x.title) == -1) ? 0 : honorsOffset;
            return x.semesters.map(function (y) {
                return gradePoint(y.average, offset);
            });
        }).flatten().average();
    }
    GPACalc.weighted = weighted;
})(GPACalc || (GPACalc = {}));
/// <reference path='data.ts'/>
/// <reference path='qmath.ts'/>
/// <reference path='query.ts'/>
// This is the GradeSpeed version. In the future, we will need to implement a
// corresponding txConnect version.
var GradeParser;
(function (GradeParser) {
    var EXTRA_CREDIT_REGEX = /^extra credit$|^ec$/i;
    var EXTRA_CREDIT_NOTE_REGEX = /extra credit/i;
    var GRADE_CELL_URL_REGEX = /\?data=([\w\d%]*)/;

    function getCourseIdFromHash(hash) {
        return hash.split('|')[3];
    }

    function parseCycle(district, $cell, idx) {
        // find a link, if any
        var $link = $cell.findTag('a');

        // if there is no link, the cell is empty; return empty values
        if (!$link.length)
            return { index: idx, average: NaN, urlHash: undefined };

        // find a grade
        var average = parseInt($link[0].innerText);
        var urlHash = GRADE_CELL_URL_REGEX.exec($link[0].attr('href'))[1];

        // return it
        return {
            index: idx,
            average: average,
            urlHash: urlHash
        };
    }

    function parseSemester(district, $cells, idx, semParams) {
        // parse cycles
        var cycles = [];
        for (var i = 0; i < semParams.cyclesPerSemester; i++) {
            cycles[i] = parseCycle(district, $cells[i], i);
        }

        // parse exam grade
        var $exam = $cells[semParams.cyclesPerSemester];
        var examGrade = NaN, examIsExempt = false;
        if ($exam.innerText === '' || $exam.innerText === '&nbsp;') {
        } else if ($exam.innerText === 'EX' || $exam.innerText === 'Exc')
            examIsExempt = true;
        else
            examGrade = parseInt($exam.innerText);

        // parse semester average
        // TODO: calculate semester average instead of parsing it? because
        // GradeSpeed sometimes messes up
        var semesterAverage = parseInt($cells[semParams.cyclesPerSemester + 1].innerText);

        // return a semester
        return {
            index: idx,
            average: semesterAverage,
            examGrade: examGrade,
            examIsExempt: examIsExempt,
            cycles: cycles
        };
    }

    function findCourseNum(district, $cells) {
        for (var i = district.columnOffsets.grades; i < $cells.length; i++) {
            var $links = $cells[i].findTag('a');
            if ($links.length !== 0) {
                return getCourseIdFromHash(atob(decodeURIComponent($links[0].attr('href').split('data=')[1])));
            }
        }

        // There is no course ID. Return nothing.
        return null;
    }

    function parseCourse(district, $row, semParams) {
        // find the cells in this row
        var $cells = $row.findTag('td');

        // find the teacher name and email
        var $teacherCell = $row.findClass('EmailLink')[0];

        // get the course number
        var courseNum = findCourseNum(district, $cells);
        var courseId = courseNum === null ? null : CryptoJS.SHA1(courseNum).toString();

        // parse semesters
        var semesters = [];
        for (var i = 0; i < semParams.semesters; i++) {
            // get cells for the semester
            var $semesterCells = [];

            // find the cells that are pertinent to this semester
            // $semesterCells becomes [cycle, cycle, ... , cycle, exam, semester] after filtering
            var cellOffset = district.columnOffsets.grades + i * (semParams.cyclesPerSemester + 2);
            for (var j = 0; j < semParams.cyclesPerSemester + 2; j++)
                $semesterCells[j] = $cells[cellOffset + j];

            // parse the semester
            semesters[i] = parseSemester(district, $semesterCells, i, semParams);
        }

        return {
            title: $cells[district.columnOffsets.title].innerText,
            teacherName: $teacherCell.innerText,
            teacherEmail: $teacherCell.attr('href').substr(7),
            courseId: courseId,
            semesters: semesters
        };
    }

    /** Gets information for all courses */
    function parseAverages(district, doc) {
        // set up DOM for parsing
        var $dom = document.createElement('div');
        $dom.innerHTML = doc;

        // find the grade table
        var $gradeTable = $dom.querySelectorAll('.DataTable')[0];

        // make semester parameters
        var $headerCells = $gradeTable.find('tr.TableHeader')[0].find('th');
        var sem = parseInt($headerCells[$headerCells.length - 1].innerText.match(/\d+/)[0]);
        var cyc = parseInt($headerCells[$headerCells.length - 3].innerText.match(/\d+/)[0]) / sem;
        var semParams = { semesters: sem, cyclesPerSemester: cyc };

        // find each course
        var $rows = $gradeTable.find('tr.DataRow, tr.DataRowAlt');

        // parse each course
        return $rows.map(function (r) {
            return parseCourse(district, r, semParams);
        });
    }
    GradeParser.parseAverages = parseAverages;

    /** Gets the name of the current student. */
    function getStudentName(district, doc) {
        var $dom = document.createElement('div');
        $dom.innerHTML = doc;
        return $dom.findClass('StudentName')[0].innerText;
    }
    GradeParser.getStudentName = getStudentName;

    function parseAssignment($row, is100Pt, catId) {
        // retrieve an element from the row and get its inner text
        var getText = function (cl) {
            return $row.find('.' + cl)[0].innerText;
        };

        // get data
        var title, dueDate, note, ptsEarned, ptsEarnedNum, ptsPossNum, weight;
        var title = getText('AssignmentName');
        var dueDate = getText('DateDue');
        var note = getText('AssignmentNote');
        var ptsEarned = getText('AssignmentGrade');
        var ptsPossNum = is100Pt ? 100 : parseInt(getText('AssignmentPointsPossible'));

        // Retrieve both the points earned and the weight of the assignment. Some teachers
        // put in assignments with weights; if so, they look like this:
        //     88x0.6
        //     90x0.2
        //     100x0.2
        // The first number is the number of points earned on the assignment; the second is
        // the weight of the assignment within the category.
        // If the weight is not specified, it is assumed to be 1.
        if (ptsEarned.indexOf('x') === -1) {
            ptsEarnedNum = parseFloat(ptsEarned);
            weight = 1;
        } else {
            var ptsSplit = ptsEarned.split('x');
            ptsEarnedNum = parseFloat(ptsSplit[0]);
            weight = parseFloat(ptsSplit[1]);
        }

        // generate the assignment ID
        var assignmentId = CryptoJS.SHA1(catId + '|' + title).toString();

        // Guess if the assignment is extra credit or not. GradeSpeed doesn't exactly
        // just tell us if an assignment is extra credit or not, but we can guess
        // from the assignment title and the note attached.
        // If either contains something along the lines of 'extra credit', we assume
        // that it is extra credit.
        var extraCredit = EXTRA_CREDIT_REGEX.test(title) || EXTRA_CREDIT_NOTE_REGEX.test(note);

        return {
            id: assignmentId,
            title: title,
            date: dueDate,
            ptsEarned: ptsEarnedNum,
            ptsPossible: ptsPossNum,
            weight: weight,
            note: note,
            extraCredit: extraCredit
        };
    }

    function parseCategory(district, catName, $cat, courseId) {
        // Try to retrieve a weight for each category. Since we have to support IB-MYP grading,
        // category weights are not guaranteed to add up to 100%. However, regardless of which
        // weighting scheme we are using, grade calculations should be able to use the weights
        // as they are parsed below.
        var catNameMatches = catName.innerText.match(/^(.*) - (\d+)%$/);
        if (catNameMatches === null) {
            catNameMatches = catName.innerText.match(/^(.*) - Each assignment counts (\d+)/);
        }

        // Find the category header so we can learn more about this category.
        var $header = $cat.find('.TableHeader')[0];

        // Some teachers don't put their assignments out of 100 points. Check if this is the case.
        var is100Pt = !$header.find('th.AssignmentPointsPossible').length;

        // Find all of the rows in this category.
        var $rows = $cat.findTag('tr');

        // Find all of the assignments.
        var $assignments = $cat.find('tr.DataRow, tr.DataRowAlt');

        // Find the average cell.
        var $averageRow = $rows[$rows.length - 1].findTag('td');
        var $averageCell;

        for (var i = 0; i < $averageRow.length; i++) {
            if ($averageRow[i].innerText.indexOf('Average') !== -1) {
                $averageCell = $averageRow[i + 1];
                break;
            }
        }

        // generate category ID
        var catId = CryptoJS.SHA1(courseId + '|' + catNameMatches[1]).toString();

        return {
            id: catId,
            title: catNameMatches[1],
            weight: parseInt(catNameMatches[2]),
            average: parseInt($averageCell.innerText),
            bonus: 0 /* TODO */ ,
            assignments: $assignments.map(function (a) {
                return parseAssignment(a, is100Pt, catId);
            })
        };
    }

    /** Gets information for a single cycle */
    function parseClassGrades(district, doc, urlHash, semesterIndex, cycleIndex) {
        // set up DOM for parsing
        var $dom = document.createElement('div');
        $dom.innerHTML = doc;

        // class name cell contains title and period
        // this array will contain something like this: ['Class Title (Period xx)', 'Class Title', 'xx']
        var classNameMatches = $dom.find('h3.ClassName')[0].innerText.match(/(.*) \(Period (\d+)\)/);

        // get category names
        var catNames = $dom.find('span.CategoryName');
        var $categories = $dom.find('.DataTable').splice(1);

        // generate course ID
        var courseId = CryptoJS.SHA1(atob(decodeURIComponent(urlHash))).toString();

        return {
            title: classNameMatches[1],
            urlHash: urlHash,
            period: parseInt(classNameMatches[2], 10),
            semesterIndex: semesterIndex,
            cycleIndex: cycleIndex,
            average: parseInt($dom.find('.CurrentAverage')[0].innerText.match(/\d+/)[0]),
            categories: $categories.pmap(catNames.toArray(), function (c, n) {
                return parseCategory(district, n, c, courseId);
            })
        };
    }
    GradeParser.parseClassGrades = parseClassGrades;
})(GradeParser || (GradeParser = {}));