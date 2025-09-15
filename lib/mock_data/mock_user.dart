import 'package:pumpkin/data_model/model/post.dart';
import 'package:pumpkin/data_model/model/user.dart';

class MockUser {
  static const List<User> mockUsers = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@example.com',
      profilePicture: 'https://example.com/profile.jpg',
    ),
    User(
      id: '2',
      name: 'Jane Doe',
      email: 'jane.doe@example.com',
      profilePicture: 'https://example.com/profile.jpg',
    ),
    User(
      id: '3',
      name: 'Jim Doe',
      email: 'jim.doe@example.com',
      profilePicture: 'https://example.com/profile.jpg',
    ),
    User(
      id: '4',
      name: 'Jill Doe',
      email: 'jill.doe@example.com',
      profilePicture: 'https://example.com/profile.jpg',
    ),
    User(
      id: '5',
      name: 'Jack Doe',
      email: 'jack.doe@example.com',
      profilePicture: 'https://example.com/profile.jpg',
    ),
  ];

  static User getUserById(String id) {
    return mockUsers.firstWhere((user) => user.id == id);
  }
}

class MockPost {
  static const List<Post> mockPosts = [   
    Post(id: '1', content: 'This is a test post 1', authorId: '1'),
    Post(id: '2', content: 'This is a test post 2', authorId: '2'),
    Post(id: '3', content: 'This is a test post 3', authorId: '3'),
    Post(id: '4', content: 'This is a test post 4', authorId: '4'),
    Post(id: '5', content: 'This is a test post 5', authorId: '5'),
  ];

  static Post getPostById(String id) {
    return mockPosts.firstWhere((post) => post.id == id);
  }
}
