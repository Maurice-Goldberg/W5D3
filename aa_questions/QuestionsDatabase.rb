require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class Question
    attr_accessor :id, :title, :body, :author_id

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL
        )
        Question.new(data.first)
    end

    def self.find_by_author_id(author_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, author_id
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?
        SQL
        )
        data.map { |question_data| Question.new(question_data) }
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    def initialize(data)
        @id = data['id']
        @title = data['title']
        @body = data['body']
        @author_id = data['author_id']
    end

    def author
        User.find_by_id(author_id)
    end

    def replies
        Reply.find_by_question_id(id)
    end

    def followers
        QuestionFollow.followers_for_question_id(id)
    end

    def likers
        QuestionLike.likers_for_question_id(id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(id)
    end
end

class User
    attr_accessor :id, :fname, :lname

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL
        )
        data.empty? ? nil : User.new(data.first)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        )
        data.empty? ? nil : User.new(data.first)
    end

    def initialize(data)
        @id = data['id']
        @fname = data['fname']
        @lname = data['lname']
    end

    def average_karma
        data = QuestionsDatabase.instance.execute(<<-SQL
            SELECT
                CAST(COUNT()), COUNT(DISTINCT())
            FROM

        SQL
        )

        num_qs = data.first['COUNT(<<<<NUM QS>>>>)']
        num_likes = data.first['COUNT(<<< NUM LIKES>>>)']
        num_likes/num_qs
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(id)
    end

    def authored_questions
        Question.find_by_author_id(id)
    end

    def authored_replies
        Reply.find_by_user_id(id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(id)
    end
end

class Reply
 attr_accessor :id, :question_id, :user_id, :parent_id, :body
    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL
        )
        Reply.new(data.first)
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id
            SELECT
                *
            FROM
                replies
            WHERE
                user_id = ?
        SQL
        )
        data.map { |reply_data| Reply.new(reply_data) }      
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id
            SELECT
                *
            FROM
                replies
            WHERE
                question_id = ?
        SQL
        )
        data.map { |reply_data| Reply.new(reply_data) }
    end

    def initialize(data)
        @id = data['id']
        @question_id = data['question_id']
        @user_id = data['user_id']
        @parent_id = data['parent_id']
        @body = data['body']
    end   

    def author
        User.find_by_id(user_id)
    end

    def question
        Question.find_by_id(question_id)
    end

    def parent_reply
        raise "This reply does not have a parent" if parent_id == nil

        Reply.find_by_id(parent_id)
    end

    def child_replies
        question.replies.select { |reply| reply.parent_id == id }
    end
end

class QuestionFollow
    attr_accessor :id, :question_id, :author_id

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id
            SELECT
                *
            FROM
                question_follows
            WHERE
                id = ?
        SQL
        )
        QuestionFollow.new(data.first)
    end

    def self.followers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id
            SELECT
                users.id, fname, lname
            FROM
                question_follows
            INNER JOIN
                users ON question_follows.author_id = users.id
            INNER JOIN
                questions ON question_follows.question_id = questions.id
            WHERE
                question_id = ?
        SQL
        )
        data.empty? ? nil : data.map { |user_data| User.new(user_data) }
    end

    def self.followed_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id
            SELECT
                questions.id, title, body, questions.author_id
            FROM
                question_follows
            INNER JOIN
                users ON question_follows.author_id = users.id
            INNER JOIN
                questions ON question_follows.question_id = questions.id
            WHERE
                question_follows.author_id = ?
        SQL
        )
        data.empty? ? nil : data.map { |question_data| Question.new(question_data) }
    end

    def self.most_followed_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n
            SELECT
                questions.id, title, body, questions.author_id, COUNT(users.id)
            FROM
                question_follows
            INNER JOIN
                users ON question_follows.author_id = users.id
            INNER JOIN
                questions ON question_follows.question_id = questions.id
            GROUP BY
                questions.id
            ORDER BY
                COUNT(users.id) DESC
            LIMIT
                ?
        SQL
        )

        data.empty? ? nil : data.map { |question_data| Question.new(question_data) }
    end

    def initialize(data)
        @id = data['id']
        @question_id = data['question_id']
        @author_id = data['author_id']
    end

end


class QuestionLike
 attr_accessor :id, :question_id, :user_id, :likes

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id
            SELECT
                *
            FROM
                question_likes
            WHERE
                id = ?
        SQL
        )
        QuestionLike.new(data.first)
    end

    def self.likers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id
            SELECT
                users.id, fname, lname
            FROM
                question_likes
            INNER JOIN
                users ON question_likes.user_id = users.id
            INNER JOIN
                questions ON question_likes.question_id = questions.id
            WHERE
                questions.id = ?
        SQL
        )

        data.empty? ? nil : data.map { |user_data| User.new(user_data) }
    end

    def self.liked_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id
            SELECT
                questions.id, title, body, questions.author_id
            FROM
                question_likes
            INNER JOIN
                users ON question_likes.user_id = users.id
            INNER JOIN
                questions ON question_likes.question_id = questions.id
            WHERE
                users.id = ?
        SQL
        )

        data.empty? ? nil : data.map { |question_data| Question.new(question_data) }
    end
    

    def self.num_likes_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id
            SELECT
                likes
            FROM
                question_likes
            WHERE
                question_id = ?
        SQL
        )
    
        data.first['likes']
    end

    def self.most_liked_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n
            SELECT
                questions.id, title, body, questions.author_id, COUNT(users.id)
            FROM
                question_likes
            INNER JOIN
                users ON question_likes.user_id = users.id
            INNER JOIN
                questions ON question_likes.question_id = questions.id
            GROUP BY
                questions.id
            ORDER BY
                COUNT(users.id) DESC
            LIMIT
                ?
        SQL
        )

        data.empty? ? nil : data.map { |question_data| Question.new(question_data) }
    end


    def initialize(data)
        @id = data['id']
        @question_id = data['question_id']
        @user_id = data['user_id']
        @likes = data['likes']
    end
end